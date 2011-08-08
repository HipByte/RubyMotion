require 'rubixir/rake/config'
require 'rubixir/rake/builder'

module Rubixir
  CONFIG = Config.new('.')
  BUILDER = Builder.new
end

desc "Build the project, then run the simulator"
task :default => :simulator

namespace :build do
  desc "Build the simulator version"
  task :simulator do
    Rubixir::BUILDER.build(Rubixir::CONFIG, 'iPhoneSimulator')
  end

  desc "Build the iOS version"
  task :ios do
    Rubixir::BUILDER.build(Rubixir::CONFIG, 'iPhoneOS')
    Rubixir::BUILDER.codesign(Rubixir::CONFIG, 'iPhoneOS')
  end

  desc "Build everything"
  task :all => [:simulator, :ios]
end

desc "Run the simulator"
task :simulator => ['build:simulator'] do
  sim = File.join(Rubixir::CONFIG.datadir, 'sim')
  app = Rubixir::CONFIG.app_bundle('iPhoneSimulator')
  family = Rubixir::CONFIG.device_family_ints[0]
  sh "#{sim} #{family} #{Rubixir::CONFIG.sdk_version} \"#{app}\""
end

desc "Create an .ipa package"
task :package => ['build:ios'] do
  tmp = "/tmp/ipa_root"
  sh "/bin/rm -rf #{tmp}"
  sh "/bin/mkdir -p #{tmp}/Payload"
  sh "/bin/cp -r \"#{Rubixir::CONFIG.app_bundle('iPhoneOS')}\" #{tmp}/Payload"
  Dir.chdir(tmp) do
    sh "/bin/chmod -R 755 Payload"
    sh "/usr/bin/zip -q -r archive.zip Payload"
  end
  sh "/bin/cp #{tmp}/archive.zip \"#{Rubixir::CONFIG.archive}\""
end

desc "Deploy on the device"
task :deploy => :package do
  deploy = File.join(Rubixir::CONFIG.datadir, 'deploy')
  flags = Rake.application.options.trace ? '-d' : ''
  sh "#{deploy} #{flags} \"#{Rubixir::CONFIG.archive}\""
end

desc "Clear build objects"
task :clean do
  rm_rf(Rubixir::CONFIG.build_dir)
end

desc "Show project config"
task :config do
  map = Rubixir::CONFIG.variables
  map.keys.sort.each do |key|
    puts key.ljust(20) + " = #{map[key].inspect}"
  end
end
