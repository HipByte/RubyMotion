require 'rubixir/rake/app'
require 'rubixir/rake/config'
require 'rubixir/rake/builder'

desc "Build the project, then run the simulator"
task :default => :simulator

namespace :build do
  desc "Build the simulator version"
  task :simulator do
    Motion::App.build('iPhoneSimulator')
  end

  desc "Build the iOS version"
  task :ios do
    Motion::App.build('iPhoneOS')
    Motion::App.codesign('iPhoneOS')
  end

  desc "Build everything"
  task :all => [:simulator, :ios]
end

desc "Run the simulator"
task :simulator => ['build:simulator'] do
  sim = File.join(Motion::App.config.datadir, 'sim')
  debug = (ENV['debug'] || '0') == '1' ? 1 : 0
  app = Motion::App.config.app_bundle('iPhoneSimulator')
  family = Motion::App.config.device_family_ints[0]
  sdk_version = Motion::App.config.sdk_version
  sh "#{sim} #{debug} #{family} #{sdk_version} \"#{app}\""
end

desc "Create an .ipa package"
task :package => ['build:ios'] do
  tmp = "/tmp/ipa_root"
  sh "/bin/rm -rf #{tmp}"
  sh "/bin/mkdir -p #{tmp}/Payload"
  sh "/bin/cp -r \"#{Motion::App.config.app_bundle('iPhoneOS')}\" #{tmp}/Payload"
  Dir.chdir(tmp) do
    sh "/bin/chmod -R 755 Payload"
    sh "/usr/bin/zip -q -r archive.zip Payload"
  end
  sh "/bin/cp #{tmp}/archive.zip \"#{Motion::App.config.archive}\""
end

desc "Deploy on the device"
task :deploy => :package do
  deploy = File.join(Motion::App.config.datadir, 'deploy')
  flags = Rake.application.options.trace ? '-d' : ''
  sh "#{deploy} #{flags} \"#{Motion::App.config.archive}\""
end

desc "Clear build objects"
task :clean do
  rm_rf(Motion::App.config.build_dir)
end

desc "Show project config"
task :config do
  map = Motion::App.config.variables
  map.keys.sort.each do |key|
    puts key.ljust(22) + " : #{map[key].inspect}"
  end
end
