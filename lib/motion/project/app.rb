# encoding: utf-8

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

require 'motion/project/template'

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
      attr_accessor :template

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
        @configs[config_mode] ||= Motion::Project::Config.make(@template, '.', config_mode)
      end

      def config
        config_without_setup.setup
      end

      def builder
        @builder ||= Motion::Project::Builder.new
      end

      def setup(&block)
        config_without_setup.setup_blocks << block
        config.setup
      end

      def pre_setup(&block)
        config_without_setup.setup_blocks << block
      end

      def post_setup(&block)
        config_without_setup.post_setup_blocks << block
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

      def profile(platform, config_plist)
        builder.profile(config, platform, config_plist)
      end

      def create(app_name, template_name=:ios)
        Motion::Project::Template.new(app_name, template_name).generate
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
