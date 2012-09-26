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
        @config_mode ||= begin
          if mode = ENV['mode']
            case mode = mode.intern
              when :development, :release
                mode
              else
                fail "Invalid value for build mode `#{mode}' (must be :development or :release)"
            end
          else
            :development
          end
        end
      end

      def config_without_setup
        @configs ||= {}
        @configs[config_mode] ||= Motion::Project::Config.new('.', config_mode)
      end

      def config
        config_without_setup.setup
      end

      def builder
        @builder ||= Motion::Project::Builder.new
      end

      def setup(&block)
        config.setup_blocks << block
      end

      def build(platform, opts={})
        builder.build(config, platform, opts)
      end

      def archive
        builder.archive(config)
      end

      def codesign(platform)
        builder.codesign(config, platform)
      end

      def create(app_name)
        unless app_name.match(/^[\w\s-]+$/)
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
# -*- coding: utf-8 -*-
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
 def generate_controller(controller_name)
      fail "Invalid controller name"  unless controller_name.match(/^[\w\s-]+$/)
      controller_file_path =  'app/'+ controller_name+'_controller.rb'
      fail "File `#{controller_file_path}' already exists"  if File.exist?(controller_file_path)
      App.log 'Creating controller', camel_case(controller_name)+"Controller"
      File.open(controller_file_path, 'w') do |io|
        io.puts <<EOS
class #{camel_case(controller_name)}Controller < UIViewController
  def viewDidLoad
  # Called when you create the class and load it. Great for initial setup and one-time-only work
  end
  def ViewWillAppear
  #Called right before your view appears, good for hiding/showing fields or any operations that you want to happen every time before the view is visible
  end
  def ViewDidAppear
  #Called after the view appears - great place to start an animations or the loading of external data
  end
end
EOS
      end
  App.log 'Created controller', camel_case(controller_name)+"Controller Done!!"
  end

    def generate_model(model_name)
        fail "Invalid model name"  unless model_name.match(/^[\w\s-]+$/)
        model_file_path =  'app/'+ model_name+'.rb'
        fail "File `#{model_file_path}' already exists"  if File.exist?(model_file_path)
        App.log 'Creating model', camel_case(model_name)
        File.open(model_file_path, 'w') do |io|
          io.puts <<EOS
class #{camel_case(model_name)}

end
EOS
        end
        App.log 'Created model', camel_case(model_name)+" Done!!"
      end


      def camel_case(some_string)
        return some_string if some_string !~ /_/ && some_string =~ /[A-Z]+.*/
        some_string.split('_').map{|e| e.capitalize}.join
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
