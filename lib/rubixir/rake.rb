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
    Rubixir::BUILDER.compile(Rubixir::CONFIG, 'iPhoneSimulator')
  end

  desc "Build the iOS version"
  task :ios do
    Rubixir::BUILDER.compile(Rubixir::CONFIG, 'iPhoneOS')
  end

  desc "Build everything"
  task :all => [:simulator, :ios]
end

desc "Run the simulator"
task :simulator => ['build:simulator'] do
  sim = File.join(Rubixir::CONFIG.platform_dir('iPhoneSimulator'), '/Developer/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator')
  app = File.join(Rubixir::CONFIG.build_dir, 'iPhoneSimulator/main')
  sh "\"#{sim}\" -SimulateApplication \"#{app}\""
end

desc "Deploy on the device"
task :deploy do
  # TODO
end

desc "Clear build objects"
task :clean do
  rm_rf(Rubixir::CONFIG.build_dir)
end
