require 'motion/project/app'
require 'motion/project/config'
require 'motion/project/builder'
require 'motion/project/vendor'

desc "Build the project, then run the simulator"
task :default => :simulator

App = Motion::Project::App

namespace :build do
  desc "Build the simulator version"
  task :simulator do
    App.build('iPhoneSimulator')
  end

  desc "Build the iOS version"
  task :ios do
    App.build('iPhoneOS')
    App.codesign('iPhoneOS')
  end

  desc "Build everything"
  task :all => [:simulator, :ios]
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

  # Launch the simulator.
  sim = File.join(App.config.bindir, 'sim')
  debug = (ENV['debug'] || '0') == '1' ? 1 : 0
  App.info 'Simulate', app
  sh "#{sim} #{debug} #{family_int} #{target} \"#{app}\""
end

desc "Create an .ipa archive"
task :archive => ['build:ios'] do
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

desc "Run specs"
task :spec do
  App.config.spec_mode = true
  Rake::Task["simulator"].invoke
end

desc "Deploy on the device"
task :deploy => :archive do
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
end

desc "Show project config"
task :config do
  map = App.config.variables
  map.keys.sort.each do |key|
    puts key.ljust(22) + " : #{map[key].inspect}"
  end
end
