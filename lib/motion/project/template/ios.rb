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
App.template = :ios

require 'motion/project'
require 'motion/project/template/ios/config'
require 'motion/project/template/ios/builder'
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
    pre_build_actions('iPhoneSimulator')
    App.build('iPhoneSimulator')
  end

  desc "Build the device version"
  task :device do
    pre_build_actions('iPhoneOS')
    App.build('iPhoneOS')
    App.codesign('iPhoneOS')
  end
end

namespace :watch do
  desc "Run the Watch application on the simulator"
  task :simulator do
    watch_extension = App.config.targets.find do |target|
      File.exist?(File.join(target.path, 'watch_app'))
    end
    unless watch_extension
      App.fail 'You can only use this task with a WatchKit application ' \
               'configured. To configure one use ' \
               '`app.target \'path/to/MyWatchApp\', :extension`.'
    end

    if ENV['type'] && ENV['type'].downcase == 'notification' && ENV['payload'].nil?
      App.fail 'The `payload=path/to/payload.json` option is required with `type=notification`.'
    end

    payload = nil
    if ENV['payload']
      payload =  File.expand_path(ENV['payload'])
      if !File.exist?(payload)
        App.fail "The payload file `#{payload}` does not exist."
      end
    end

    unless ENV["skip_build"]
      Rake::Task["build:simulator"].invoke
    end

    kernel_path = nil
    target_triple = nil
    if watch_extension.type == :watchapp
      kernel_path = File.join(App.config.datadir, '../../watchos/2.0', 'WatchSimulator', "kernel-i386.bc")
      target_triple = "i386-apple-ios2.0.0"
    else
      kernel_path = File.join(App.config.datadir, 'iPhoneSimulator', "kernel-x86_64.bc")
      target_triple = "x86_64-apple-ios5.0.0"
    end
    app_bundle = File.expand_path(App.config.app_bundle('iPhoneSimulator'))

    repl_launcher = Motion::Project::REPLLauncher.new({
      "arguments" => ENV['args'],
      "debug-mode" => !!ENV['debug'],
      "start-suspended" => !!ENV['no_continue'],
      "app-bundle-path" => app_bundle,
      "xcode-path" => App.config.xcode_dir,
      "device-name" => ENV["device_name"],
      "watchkit-notification-payload" => payload,
      "watchkit-launch-mode" => ENV['type'],
      "display-type" => ENV['display'],
      "kernel-path" => kernel_path,
      "target-triple" => target_triple,
      "local-port" => watch_extension.local_repl_port,
      "device-hostname" => "0.0.0.0",
      "sdk-version" => App.config.sdk_version,
      "device-family" => App.config.device_family_ints[0],
      "platform" => "WatchOSSimulator",
      "bs_files" => [App.config.bridgesupport_files, App.config.vendor_projects.map(&:bs_files)].flatten,
      "verbose" => App::VERBOSE
    })

    at_exit { system("stty echo") } if $stdout.tty? # Just in case the simulator launcher crashes and leaves the terminal without echo.
    Signal.trap(:INT) { } if ENV['debug']
    repl_launcher.launch
    App.config.print_crash_message if $?.exitstatus != 0 && !App.config.spec_mode
    exit($?.exitstatus)
  end

  # TODO add shortcut task to invoke the IB rake task of the watch app target.
  # desc "Open the Watch application's Storyboard in Interface Builder"
  # task :ib do
  # end
end

desc "Same as 'watch:simulator'"
task :watch => 'watch:simulator'

desc "Run the simulator"
task :simulator do
  deployment_target = Motion::Util::Version.new(App.config.deployment_target)
  target = ENV['target']
  if target && Motion::Util::Version.new(target) < deployment_target
    App.fail "It is not possible to simulate an SDK version (#{target}) " \
             "lower than the app's deployment target (#{deployment_target})"
  end
  target ||= App.config.sdk_version

  family_int = App.config.device_family_ints[0]
  if family = ENV['device_family']
    family_int = App.config.device_family_int(family.downcase.intern)
  end

  if ENV['background_fetch']
    modes = App.config.info_plist['UIBackgroundModes']
    if modes.nil? || !modes.include?('fetch')
      App.fail "In order to launch the application in `background fetch' " \
               "mode, you will need to configure your application to enable " \
               "it by adding: app.info_plist['UIBackgroundModes'] = ['fetch']"
    end
  end

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

  # Cleanup the simulator application sandbox, to avoid having old resource files there.
  if ENV['clean']
    sim_apps = File.expand_path("~/Library/Application Support/iPhone Simulator/#{target}/Applications")
    Dir.glob("#{sim_apps}/**/*.app").each do |app_bundle|
      if File.basename(app_bundle) == File.basename(app)
        rm_rf File.dirname(app_bundle)
        break
      end
    end
  end

  if App.config.archs['iPhoneSimulator'].include?('x86_64')
    kernel_path = File.join(App.config.datadir, 'iPhoneSimulator', "kernel-x86_64.bc")
  else
    kernel_path = File.join(App.config.datadir, 'iPhoneSimulator', "kernel-i386.bc")
  end
  app_bundle = File.expand_path(App.config.app_bundle('iPhoneSimulator'))

  retina = ENV['retina']
  device_name = ENV["device_name"]
  device_name = App.config.device_family_string(device_name, family_int, target, retina)
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
    "local-port" => App.config.local_repl_port('iPhoneSimulator'),
    "device-hostname" => "0.0.0.0",
    "sdk-version" => target,
    "device-family" => family_int,
    "platform" => "iPhoneSimulator",
    "bs_files" => [App.config.bridgesupport_files, App.config.vendor_projects.map(&:bs_files)].flatten,
    "verbose" => App::VERBOSE
  })

  App.info 'Simulate', app_bundle
  at_exit { system("stty echo") } if $stdout.tty? # Just in case the simulator launcher crashes and leaves the terminal without echo.
  Signal.trap(:INT) { } if ENV['debug']
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

$deployed_app_path = nil

desc "Deploy on the device"
task :device => :archive do
  App.info 'Deploy', App.config.archive
  device_id = (ENV['id'] or App.config.device_id).downcase
  unless App.config.provisions_all_devices? || App.config.provisioned_devices.include?(device_id)
    App.fail "Device ID `#{device_id}' not provisioned in profile `#{App.config.provisioning_profile}'"
  end
  env = "XCODE_DIR=\"#{App.config.xcode_dir}\""

  repl_mode = false
  if ENV['debug']
    env << " RM_AVAILABLE_ARCHS='#{App.config.archs['iPhoneOS'].join(':')}'"
  elsif !ENV['install_only']
    env << " RM_ENABLE_REPL=true"
    repl_mode = true
  end

  deploy = File.join(App.config.bindir, 'ios/deploy')
  flags = Rake.application.options.trace ? '-d' : ''
  Signal.trap(:INT) { } if ENV['debug']
  cmd = "#{env} #{deploy} #{flags} \"#{device_id}\" \"#{App.config.archive}\""
  remote_arch = nil

  if ENV['install_only']
    $deployed_app_path = `#{cmd}`.strip
  elsif ENV['debug']
    system(cmd)
  else
    remote_arch = `#{cmd}`.strip
  end

  if repl_mode
    kernel_path = nil
    target_triple = nil

    if remote_arch.include?('arm64') && App.config.archs['iPhoneOS'].include?('arm64')
      kernel_path = "kernel-arm64.bc"
    else
      kernel_path = "kernel-armv7.bc"
    end

    kernel = File.join(App.config.datadir, "iPhoneOS", kernel_path)

    repl_launcher = Motion::Project::REPLLauncher.new({
      "arguments" => ENV['args'],
      "debug-mode" => !!ENV['debug'],
      "spec-mode" => App.config.spec_mode,
      "kernel-path" => kernel,
      "local-port" => TCPServer.new('localhost', 0).addr[1],
      "remote-port" => App.config.local_repl_port('iPhoneOS'),
      "device-hostname" => "0.0.0.0",
      "platform" => "iPhoneOS",
      "device-id" => device_id,
      "app-bundle-path" => App.config.app_bundle('iPhoneOS'),
      "bs_files" => [App.config.bridgesupport_files, App.config.vendor_projects.map(&:bs_files)].flatten,
      "verbose" => App::VERBOSE
    })

    repl_launcher.launch
  end
end

desc "Create a .a static library"
task :static do
  if Motion::Project::Config.starter?
    App.fail "You are using RubyMotion Starter. 'rake static' not supported in this release. If you would like to create static libraries you can purchase a paid subscription."
  end
  libs = %w{iPhoneSimulator iPhoneOS}.map do |platform|
    '"' + App.build(platform, :static => true) + '"'
  end
  fat_lib = File.join(App.config.build_dir, App.config.name + '-universal.a')
  App.info 'Create', fat_lib
  sh "/usr/bin/lipo -create #{libs.join(' ')} -output \"#{fat_lib}\""
end

# With Xcode 5 not all templates worked on the sim or device.
#
# TODO: This should be cleaned up once Xcode 5 is no longer supported.
IOS_SIM_INSTRUMENTS_TEMPLATES = [
  'Allocations', 'Leaks', 'Activity Monitor',
  'Zombies', 'Time Profiler', 'System Trace', 'Automation',
  'File Activity', 'Core Data'
]
IOS_DEVICE_INSTRUMENTS_TEMPLATES = [
  'Allocations', 'Leaks', 'Activity Monitor',
  'Zombies', 'Time Profiler', 'System Trace', 'Automation',
  'Energy Diagnostics', 'Network', 'System Usage', 'Core Animation',
  'OpenGL ES Driver', 'OpenGL ES Analysis'
]

desc "Same as profile:simulator"
task :profile => ['profile:simulator']

def profiler_templates
  if App.config.xcode_version[0] >= '6.0'
    App.config.profiler_known_templates.map do |template_path|
      File.basename(template_path, File.extname(template_path))
    end
  end
end

namespace :profile do
  desc "Run a build on the simulator through Instruments"
  task :simulator do
    Rake::Task['build:simulator'].invoke

    target = ENV['target'] || App.config.sdk_version
    family_int =
      if family = ENV['device_family']
        App.config.device_family_int(family.downcase.intern)
      else
        App.config.device_family_ints[0]
      end
    retina = ENV['retina']
    device_name = ENV["device_name"]
    device_name = App.config.device_family_string(device_name, family_int, target, retina)

    plist = App.config.profiler_config_plist('iPhoneSimulator', ENV['args'], ENV['template'], profiler_templates || IOS_SIM_INSTRUMENTS_TEMPLATES)
    plist['com.apple.xcode.simulatedDeviceFamily'] = App.config.device_family_ints.first
    plist['com.apple.xcode.SDKPath'] = App.config.sdk('iPhoneSimulator')
    plist['optionalData']['launchOptions']['architectureType'] = 0
    plist['deviceIdentifier'] = App.config.profiler_config_device_identifier(device_name, target)
    App.profile('iPhoneSimulator', plist)
  end

  namespace :simulator do
    desc 'List all built-in Simulator Instruments templates'
    task :templates do
      puts "Built-in Simulator Instruments templates:"
      (profiler_templates || IOS_SIM_INSTRUMENTS_TEMPLATES).each do |template|
        puts "* #{template}"
      end
    end
  end

  desc "Run a build on the device through Instruments"
  task :device do
    # Create a build that allows debugging but doesn't start a debugger on deploy.
    App.config.entitlements['get-task-allow'] = true
    ENV['install_only'] = '1'
    Rake::Task['device'].invoke

    if $deployed_app_path.nil? || $deployed_app_path.empty?
      App.fail 'Unable to determine remote app path'
    end

    plist = App.config.profiler_config_plist('iPhoneOS', ENV['args'], ENV['template'], profiler_templates || IOS_DEVICE_INSTRUMENTS_TEMPLATES, false)
    plist['absolutePathOfLaunchable'] = File.join($deployed_app_path, App.config.bundle_name)
    plist['deviceIdentifier'] = (ENV['id'] or App.config.device_id)
    App.profile('iPhoneOS', plist)
  end

  namespace :device do
    desc 'List all built-in device Instruments templates'
    task :templates do
      puts "Built-in device Instruments templates:"
      (profiler_templates || IOS_DEVICE_INSTRUMENTS_TEMPLATES).each do |template|
        puts "* #{template}"
      end
    end
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
    logs = Dir.glob(File.join(crash_reports_dir, "#{App.config.name}_*"))
    unless logs.empty?
      sh "/usr/bin/open -a Console \"#{logs.last}\""
    end
  end
end

