# Copyright (C) 2012, HipByte SPRL. All Rights Reserved.
#
# This file is subject to the terms and conditions of the End User License
# Agreement accompanying the package this file is a part of.

module Motion; module Project
  class App
    VERBOSE =
      begin
        if Rake.send(:verbose) != true
          Rake.send(:verbose, false)
          false
        else
          true
        end
      rescue
        true
      end

    class << self
      def config_mode
        @config_mode or :development
      end

      def config_mode=(mode)
        @config_mode = mode
      end

      def configs
        @configs ||= {
          :development => Motion::Project::Config.new('.', :development),
          :release => Motion::Project::Config.new('.', :release)
        }
      end

      def config
        configs[config_mode]
      end

      def builder
        @builder ||= Motion::Project::Builder.new
      end

      def setup
        configs.each_value { |x| yield x }
        config.validate
      end

      def build(platform)
        builder.build(config, platform)
      end

      def archive
        builder.archive(config)
      end

      def codesign(platform)
        builder.codesign(config, platform)
      end

      def create(app_name)
        unless app_name.match(/^[a-zA-Z\d\s]+$/)
          fail "Invalid app name"
        end
    
        if File.exist?(app_name)
          fail "Directory `#{app_name}' already exists"
        end

        App.log 'Create', app_name 
        Dir.mkdir(app_name)
        Dir.chdir(app_name) do
          App.log 'Create', File.join(app_name, '.gitignore')
          File.open('.gitignore', 'w') do |io|
            io.puts ".repl_history"
            io.puts "build"
            io.puts "resources/*.nib"
            io.puts "resources/*.momd"
            io.puts "resources/*.storyboardc"
          end
          App.log 'Create', File.join(app_name, 'Rakefile')
          File.open('Rakefile', 'w') do |io|
            io.puts <<EOS
$:.unshift(\"#{$motion_libdir}\")
require 'motion/project'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = '#{app_name}'
end
EOS
          end
          App.log 'Create', File.join(app_name, 'app')
          Dir.mkdir('app')
          App.log 'Create', File.join(app_name, 'app/app_delegate.rb')
          File.open('app/app_delegate.rb', 'w') do |io|
            io.puts <<EOS
class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    true
  end
end
EOS
          end
          App.log 'Create', File.join(app_name, 'resources')
          Dir.mkdir('resources')
          App.log 'Create', File.join(app_name, 'spec')
          Dir.mkdir('spec')
          App.log 'Create', File.join(app_name, 'spec/main_spec.rb')
          File.open('spec/main_spec.rb', 'w') do |io|
            io.puts <<EOS
describe "Application '#{app_name}'" do
  before do
    @app = UIApplication.sharedApplication
  end

  it "has one window" do
    @app.windows.size.should == 1
  end
end
EOS
          end
        end
      end

      def log(what, msg)
        require 'thread'
        @print_mutex ||= Mutex.new
        # Because this method can be called concurrently, we don't want to mess any output.
        @print_mutex.synchronize do
          what = "\e[1m" + what.rjust(10) + "\e[0m" # bold
          $stderr.puts what + ' ' + msg 
        end
      end

      def warn(msg)
        log 'WARNING!', msg
      end

      def fail(msg)
        log 'ERROR!', msg
        exit 1
      end

      def info(what, msg)
        log what, msg unless VERBOSE
      end
    end
  end
end; end
