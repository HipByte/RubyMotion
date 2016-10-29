# encoding: utf-8

# Copyright (c) 2012, HipByte SPRL and contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'motion/project/app'
require 'motion/util/version'

App = Motion::Project::App
App.template = :tvos

require 'motion/project'
require 'motion/project/template/tvos/config'
require 'motion/project/template/tvos/builder'
require 'motion/project/repl_launcher'

desc "Build the project, then run the simulator"
task :default => :simulator

desc "Build everything"
task :build => ['build:simulator', 'build:device']

namespace :build do
  def pre_build_actions(platform)
    # TODO: Ensure Info.plist gets regenerated on each build so it has ints for
    # Instruments and strings for normal builds.
    rm_f File.join(App.config.app_bundle(platform), 'Info.plist')

    # TODO this should go into a iOS specific Builder class which performs this
    # check before building.
    App.config.resources_dirs.flatten.each do |dir|
      next unless File.exist?(dir)
      Dir.entries(dir).grep(/^Resources$/i).each do |basename|
        path = File.join(dir, basename)
        if File.directory?(path)
          suggestion = basename == 'Resources' ? 'Assets' : 'assets'
          App.fail "An iOS application cannot be installed if it contains a " \
                   "directory called `resources'. Please rename the " \
                   "directory at path `#{path}' to, for instance, " \
                   "`#{File.join(dir, suggestion)}'."
        end
      end
    end
  end

  desc "Build the simulator version"
  task :simulator do
    pre_build_actions('AppleTVSimulator')
    App.build('AppleTVSimulator')
  end

  desc "Build the device version"
  task :device do
    pre_build_actions('AppleTVOS')
    App.build('AppleTVOS')
    App.codesign('AppleTVOS')
  end
end

desc "Run the simulator"
task :simulator do
  deployment_target = Motion::Util::Version.new(App.config.deployment_target)

  target = ENV['target']
  if target && Motion::Util::Version.new(target) < deployment_target
    App.fail "It is not possible to simulate an SDK version (#{target}) " \
             "lower than the app's deployment target (#{deployment_target})"
  end
  target ||= App.config.sdk_version

  unless ENV["skip_build"]
    Rake::Task["build:simulator"].invoke
  end

  if ENV['TMUX']
    tmux_default_command = `tmux show-options -g default-command`.strip
    unless tmux_default_command.include?("reattach-to-user-namespace")
      App.warn(<<END

    It appears you are using tmux without 'reattach-to-user-namespace', the simulator might not work properly. You can either disable tmux or run the following commands:

      $ brew install reattach-to-user-namespace
      $ echo 'set-option -g default-command "reattach-to-user-namespace -l $SHELL"' >> ~/.tmux.conf

END
      )
    end
  end

  # TODO: Do not hardcode
  device_name = "Apple TV 1080p"

  app_bundle = App.config.app_bundle('AppleTVSimulator')
  target_triple = "x86_64-apple-ios9.1.0"
  kernel_path = File.join(App.config.datadir, "AppleTVSimulator", "kernel-x86_64.bc")

  # Launch the simulator.
  repl_launcher = Motion::Project::REPLLauncher.new({
    "arguments" => ENV['args'],
    "debug-mode" => !!ENV['debug'],
    "spec-mode" => App.config.spec_mode,
    "start-suspended" => !!ENV['no_continue'],
    "app-bundle-path" => app_bundle,
    "xcode-path" => App.config.xcode_dir,
    "device-name" => device_name,
    "background-fetch" => !!ENV['background_fetch'],
    "kernel-path" => kernel_path,
    "target-triple" => target_triple,
    "local-port" => App.config.local_repl_port('AppleTVSimulator'),
    "device-hostname" => "0.0.0.0",
    "sdk-version" => target,
    "device-family" => "3",
    "platform" => "AppleTVSimulator",
    "bs_files" => [App.config.bridgesupport_files, App.config.vendor_projects.map(&:bs_files)].flatten,
    "verbose" => App::VERBOSE
  })

  App.info 'Simulate', app_bundle
  at_exit { system("stty echo") } if $stdout.tty? # Just in case the simulator launcher crashes and leaves the terminal without echo.
  Signal.trap(:INT) {} if ENV['debug']
  repl_launcher.launch
  App.config.print_crash_message if $?.exitstatus != 0 && !App.config.spec_mode
  exit($?.exitstatus)
end

desc "Create an .ipa archive"
task :archive => ['build:device'] do
  App.archive
end

namespace :archive do
  desc "Create an .ipa archive for distribution (AppStore)"
  task :distribution do
    App.config_without_setup.build_mode = :release
    App.config_without_setup.distribution_mode = true
    Rake::Task["archive"].invoke
  end
end

desc "Same as 'spec:simulator'"
task :spec => ['spec:simulator']

namespace :spec do
  desc "Run the test/spec suite on the simulator"
  task :simulator do
    App.config_without_setup.spec_mode = true
    Rake::Task["simulator"].invoke
  end

  desc "Run the test/spec suite on the device"
  task :device do
    App.config_without_setup.spec_mode = true
    Rake::Task["device"].invoke
  end
end

desc "Deploy on the device"
task :device => :archive do
  App.info 'Deploy', App.config.archive
  device_id = (ENV['id'] or App.config.device_id)
  unless App.config.provisions_all_devices? || App.config.provisioned_devices.include?(device_id)
    App.fail "Device ID `#{device_id}' not provisioned in profile `#{App.config.provisioning_profile}'"
  end
  env = "XCODE_DIR=\"#{App.config.xcode_dir}\""

  repl_mode = false
  if ENV['debug']
    env << " RM_AVAILABLE_ARCHS='#{App.config.archs['AppleTVOS'].join(':')}'"
  elsif !ENV['install_only']
    repl_mode = true
  end

  deploy = File.join(App.config.bindir, 'ios/deploy')
  flags = Rake.application.options.trace ? '-d' : ''
  Signal.trap(:INT) {} if ENV['debug']
  cmd = "#{env} #{deploy} #{flags} -tvos \"#{device_id}\" \"#{App.config.archive}\""
  system(cmd)

  if repl_mode
    target_triple = "arm64-apple-ios7.0.0"
    kernel = File.join(App.config.datadir, "AppleTVOS", "kernel-arm64.bc")

    repl_launcher = Motion::Project::REPLLauncher.new({
      "arguments" => ENV['args'],
      "debug-mode" => !!ENV['debug'],
      "spec-mode" => App.config.spec_mode,
      "kernel-path" => kernel,
      "target-triple" => target_triple,
      "local-port" => TCPServer.new('localhost', 0).addr[1],
      "remote-port" => App.config.local_repl_port('AppleTVOS'),
      "device-hostname" => "0.0.0.0",
      "platform" => "iPhoneOS",
      "device-id" => device_id,
      "app-bundle-path" => App.config.app_bundle('AppleTVOS'),
      "bs_files" => [App.config.bridgesupport_files, App.config.vendor_projects.map(&:bs_files)].flatten,
      "verbose" => App::VERBOSE
    })

    repl_launcher.launch
  end
end

desc "Same as crashlog:simulator"
task :crashlog => 'crashlog:simulator'

namespace :crashlog do
  desc "Open the latest crash report generated by the app in the simulator"
  task :simulator => :__local_crashlog

  desc "Retrieve and symbolicate crash logs generated by the app on the device, and open the latest generated one"
  task :device do
    device_id = (ENV['id'] or App.config.device_id)
    crash_reports_dir = File.expand_path("~/Library/Logs/RubyMotion Device")
    mkdir_p crash_reports_dir
    deploy = File.join(App.config.bindir, 'ios/deploy')
    env = "XCODE_DIR=\"#{App.config.xcode_dir}\" CRASH_REPORTS_DIR=\"#{crash_reports_dir}\""
    flags = Rake.application.options.trace ? '-d' : ''
    cmd = "#{env} #{deploy} -l #{flags} \"#{device_id}\" \"#{App.config.archive}\""
    system(cmd)

    # Open the latest generated one.
    logs = Dir.glob(File.join(crash_reports_dir, "#{App.config.name}{_,-}*"))
    unless logs.empty?
      sh "/usr/bin/open -a Console \"#{logs.last}\""
    end
  end
end
