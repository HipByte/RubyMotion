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
  app = Rubixir::CONFIG.app_bundle('iPhoneSimulator', true)
  sim = File.join(Rubixir::CONFIG.platform_dir('iPhoneSimulator'), '/Developer/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator')
  sh "\"#{sim}\" -SimulateApplication \"#{app}\""
end

desc "Create an .ipa package"
task :package => ['build:ios'] do
  tmp = "/tmp/ipa_root"
  rm_rf tmp
  mkdir_p "#{tmp}/Payload"
  cp_r Rubixir::CONFIG.app_bundle('iPhoneOS'), "#{tmp}/Payload"
  Dir.chdir(tmp) do
    sh "/bin/chmod -R 755 Payload"
    sh "/usr/bin/zip -r archive.zip Payload"
  end
  cp "#{tmp}/archive.zip", Rubixir::CONFIG.archive
end

desc "Deploy on the device"
task :deploy => :package do
  deploy = File.join(Rubixir::CONFIG.datadir, 'deploy')
  sh "#{deploy} #{Rubixir::CONFIG.archive}"
end

desc "Clear build objects"
task :clean do
  rm_rf(Rubixir::CONFIG.build_dir)
end
