# Copyright (C) 2012, HipByte SPRL. All Rights Reserved.
#
# This file is subject to the terms and conditions of the End User License
# Agreement accompanying the package this file is a part of.

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

desc "Run the simulator"
task :simulator => ['build:simulator'] do
  app = App.config.app_bundle('iPhoneSimulator')
  target = App.config.deployment_target

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
  retina = ENV['retina'] == 'true'

  # Configure the SimulateDevice variable (the only way to specify if we want to run in retina mode or not).
  sh "/usr/bin/defaults write com.apple.iphonesimulator \"SimulateDevice\" \"'#{App.config.device_family_string(family_int, retina)}'\""

  # Launch the simulator.
  xcode = App.config.xcode_dir
  env = xcode.match(/^\/Applications/) ? "DYLD_FRAMEWORK_PATH=\"#{xcode}/../Frameworks\":\"#{xcode}/../OtherFrameworks\"" : ''
  sim = File.join(App.config.bindir, 'sim')
  debug = (ENV['debug'] || (App.config.spec_mode ? '0' : '2')).to_i
  debug = 2 if debug < 0 or debug > 2
  App.info 'Simulate', app
  at_exit { system("stty echo") } # Just in case the simulator launcher crashes and leaves the terminal without echo.
  sh "#{env} #{sim} #{debug} #{family_int} #{target} \"#{xcode}\" \"#{app}\""
end

desc "Create archives for everything"
task :archive => ['archive:development', 'archive:release']

def create_ipa
  app_bundle = App.config.app_bundle('iPhoneOS')
  archive = App.config.archive
  if !File.exist?(archive) or File.mtime(app_bundle) > File.mtime(archive)
    App.info 'Create', archive
    tmp = "/tmp/ipa_root"
    sh "/bin/rm -rf #{tmp}"
    sh "/bin/mkdir -p #{tmp}/Payload"
    sh "/bin/cp -r \"#{app_bundle}\" #{tmp}/Payload"
    Dir.chdir(tmp) do
      sh "/bin/chmod -R 755 Payload"
      sh "/usr/bin/zip -q -r archive.zip Payload"
    end
    sh "/bin/cp #{tmp}/archive.zip \"#{archive}\""
  end
end

namespace :archive do
  desc "Create an .ipa archive for development"
  task :development do
    App.config_mode = :development
    Rake::Task["build:device"].execute
    App.archive
  end

  desc "Create an .ipa for release (AppStore)"
  task :release do
    App.config_mode = :release
    Rake::Task["build:device"].execute
    App.archive
  end
end

desc "Run specs"
task :spec do
  App.config.spec_mode = true
  Rake::Task["simulator"].invoke
end

desc "Deploy on the device"
task :device => 'archive:development' do
  App.info 'Deploy', App.config.archive
  unless App.config.provisioned_devices.include?(App.config.device_id)
    App.fail "Connected device ID `#{App.config.device_id}' not provisioned in profile `#{App.config.provisioning_profile}'"
  end
  deploy = File.join(App.config.bindir, 'deploy')
  flags = Rake.application.options.trace ? '-d' : ''
  sh "#{deploy} #{flags} \"#{App.config.device_id}\" \"#{App.config.archive}\""
end

desc "Clear build objects"
task :clean do
  App.info 'Delete', App.config.build_dir
  rm_rf(App.config.build_dir)
  App.config.vendor_projects.each { |vendor| vendor.clean }
  Dir.glob(App.config.resources_dir + '/**/*.{nib,storyboardc,momd}').each do |p|
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
