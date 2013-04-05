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

require 'motion/version'
require 'motion/project/app'
require 'motion/project/config'
require 'motion/project/builder'
require 'motion/project/vendor'
require 'motion/project/plist'

App = Motion::Project::App

# Check for software updates.
system('/usr/bin/motion update --check')
if $?.exitstatus == 2
  puts '=' * 80
  puts " A new version of RubyMotion is available. Run `sudo motion update' to upgrade."
  puts '=' * 80
  puts ''
end

desc "Build the project, then run the simulator"
task :default => :simulator

desc "Build everything"
task :build => ['build:simulator', 'build:device']

namespace :build do
  desc "Build the simulator version"
  task :simulator do
    App.build('iPhoneSimulator')
  end

  desc "Build the device version"
  task :device do
    App.build('iPhoneOS')
    App.codesign('iPhoneOS')
  end
end

desc "Build and run the simulator"
task :simulator => ['build:simulator', 'sim'] do
end

desc "Run the simulator"
task :sim do
  app = App.config.app_bundle('iPhoneSimulator')
  target = ENV['target'] || App.config.sdk_version

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

  # Prepare the device family.
  family_int =
    if family = ENV['device_family']
      App.config.device_family_int(family.downcase.intern)
    else
      App.config.device_family_ints[0]
    end
  retina = ENV['retina']

  # Configure the SimulateDevice variable (the only way to specify if we want to run in retina mode or not).
  simulate_device = App.config.device_family_string(family_int, target, retina)
  default_simulator = `/usr/bin/defaults read com.apple.iphonesimulator "SimulateDevice"`.strip
  if default_simulator != simulate_device && default_simulator != "'#{simulate_device}'"
    system("/usr/bin/killall \"iPhone Simulator\" >& /dev/null")
    system("/usr/bin/defaults write com.apple.iphonesimulator \"SimulateDevice\" \"'#{simulate_device}'\"")
  end

  # Launch the simulator.
  xcode = App.config.xcode_dir
  env = "DYLD_FRAMEWORK_PATH=\"#{xcode}/../Frameworks\":\"#{xcode}/../OtherFrameworks\""
  env << ' SIM_SPEC_MODE=1' if App.config.spec_mode
  sim = File.join(App.config.bindir, 'sim')
  debug = (ENV['debug'] ? 1 : (App.config.spec_mode ? '0' : '2'))
  App.info 'Simulate', app
  at_exit { system("stty echo") } if $stdout.tty? # Just in case the simulator launcher crashes and leaves the terminal without echo.
  sh "#{env} #{sim} #{debug} #{family_int} #{target} \"#{xcode}\" \"#{app}\""
end

desc "Create an .ipa archive"
task :archive => ['build:device'] do
  App.archive
end

namespace :archive do
  desc "Create an .ipa archive for distribution (AppStore)"
  task :distribution do
    App.config_without_setup.build_mode = :release
    App.config.distribution_mode = true
    Rake::Task["build:device"].invoke
    App.archive
  end
end

desc "Same as 'spec:simulator'"
task :spec => ['spec:simulator']

namespace :spec do
  desc "Run the test/spec suite on the simulator"
  task :simulator do
    App.config.spec_mode = true
    Rake::Task["simulator"].invoke
  end

  desc "Run the test/spec suite on the device"
  task :device do
    App.config.spec_mode = true
    ENV['debug'] ||= '1'
    Rake::Task["device"].invoke
  end
end

desc "Deploy on the device"
task :device => :archive do
  App.info 'Deploy', App.config.archive
  device_id = (ENV['id'] or App.config.device_id)
  unless App.config.provisioned_devices.include?(device_id)
    App.fail "Device ID `#{device_id}' not provisioned in profile `#{App.config.provisioning_profile}'"
  end
  env = "XCODE_DIR=\"#{App.config.xcode_dir}\""
  deploy = File.join(App.config.bindir, 'deploy')
  flags = Rake.application.options.trace ? '-d' : ''
  sh "#{env} #{deploy} #{flags} \"#{device_id}\" \"#{App.config.archive}\""
end

desc "Clear build objects"
task :clean do
  App.info 'Delete', App.config.build_dir
  rm_rf(App.config.build_dir)
  App.config.vendor_projects.each { |vendor| vendor.clean }
  Dir.glob(App.config.resources_dirs.flatten.map{ |x| x + '/**/*.{nib,storyboardc,momd}' }).each do |p|
    App.info 'Delete', p
    rm_rf p
  end
end

desc "Show project config"
task :config do
  map = App.config.variables
  map.keys.sort.each do |key|
    puts key.ljust(22) + " : #{map[key].inspect}"
  end
end

desc "Generate ctags"
task :ctags do
  tags_file = 'tags'
  config = App.config
  if !File.exist?(tags_file) or File.mtime(config.project_file) > File.mtime(tags_file)
    bs_files = config.bridgesupport_files + config.vendor_projects.map { |p| Dir.glob(File.join(p.path, '*.bridgesupport')) }.flatten
    ctags = File.join(config.bindir, 'ctags')
    config = File.join(config.motiondir, 'data', 'bridgesupport-ctags.cfg')
    sh "#{ctags} --options=\"#{config}\" #{bs_files.map { |x| '"' + x + '"' }.join(' ')}"
  end
end

desc "Create a .a static library"
task :static do
  libs = %w{iPhoneSimulator iPhoneOS}.map do |platform|
    '"' + App.build(platform, :static => true) + '"'
  end
  fat_lib = File.join(App.config.build_dir, App.config.name + '-universal.a')
  App.info 'Create', fat_lib
  sh "/usr/bin/lipo -create #{libs.join(' ')} -output \"#{fat_lib}\""
end

=begin
# Automatically load project extensions. A project extension is a gem whose
# name starts with `motion-' and which exposes a `lib/motion/project' libdir.
require 'rubygems'
Gem.path.each do |gemdir|
  Dir.glob(File.join(gemdir, 'gems', '*')).each do |gempath|
    base = File.basename(gempath)
    if md = base.match(/^(motion-.*)-((\d+\.)*\d+)/) and File.exist?(File.join(gempath, 'lib', 'motion', 'project'))
      ext_name = md[1]
      begin
        require ext_name
      rescue LoadError => e
        $stderr.puts "Can't autoload extension `#{ext_name}': #{e.message}"
      end
    end
  end
end
=end
