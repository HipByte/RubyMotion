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

require 'erb'

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

      def create(app_name, template_name="ios")
        Template.new(app_name, template_name).generate
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

    class Template
      # for ERB
      attr_reader :name

      def initialize(app_name, template_name)
        @name = @app_name = app_name
        @template_name = template_name
        @template_directory = File.expand_path(File.join(__FILE__, "../../template/#{@template_name}"))

        unless app_name.match(/^[\w\s-]+$/)
          fail "Invalid app name"
        end

        if File.exist?(app_name)
          fail "Directory `#{app_name}' already exists"
        end

        unless File.exist?(@template_directory)
          fail "Invalid template name"
        end
      end

      def generate
        App.log 'Create', @app_name
        FileUtils.mkdir(@app_name)

        Dir.chdir(@app_name) do
          create_directories()
          create_files()
        end
      end

      private

      def template_directory
        @template_directory
      end

      def create_directories
        Dir.glob(File.join(template_directory, "**/")).each do |dir|
          dir.sub!("#{template_directory}/", '')
          FileUtils.mkdir_p(dir) if dir.length > 0
        end
      end

      def create_files
        Dir.glob(File.join(template_directory, "**/*"), File::FNM_DOTMATCH).each do |src|
          dest = src.sub("#{template_directory}/", '')
          next if File.directory?(src)
          next if dest.include?(".DS_Store")

          dest = replace_file_name(dest)
          if dest =~ /(.+)\.erb$/
            App.log 'Create', "#{@app_name}/#{$1}"
            File.open($1, "w") { |io|
              io.print ERB.new(File.read(src)).result(binding)
            }
          else
            App.log 'Create', "#{@app_name}/#{dest}"
            FileUtils.cp(src, dest)
          end
        end
      end

      def replace_file_name(file_name)
        file_name = file_name.sub("{name}", "#{@name}")
        file_name
      end
    end
  end
end; end
