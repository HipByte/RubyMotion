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

require 'motion/project/builder'

module Motion; module Project
  class Target
    include Rake::DSL if Object.const_defined?(:Rake) && Rake.const_defined?(:DSL)

    attr_accessor :type
    attr_reader :path

    def initialize(path, type, config, opts)
      @path = path
      @full_path = File.expand_path(path)
      @type = type
      @config = config
      @opts = opts
    end

    # Builds the target's product for the specified `platform` and the
    # configured `distribution_mode`.
    #
    # @param [String] platform
    #        The platform identifier that's being build for, such as
    #        `iPhoneSimulator` or `iPhoneOS`.
    #
    # @return [void]
    #
    def build(platform)
      @platform = platform

      task = if platform == 'iPhoneSimulator'
        "build:simulator"
      else
        if @config.distribution_mode
          "archive:distribution"
        else
          "build:device"
        end
      end

      unless rake(task)
        App.fail "Target '#{@path}' failed to build"
      end
    end

    # Cleans the target's product.
    #
    # @return [void]
    #
    def clean
      rake 'clean'
    end

    # @return [String] The path to the platform + configuration based directory.
    #
    def build_dir
      @build_dir ||= begin
        build_path = File.join(@path, 'build', '*')
        Dir[build_path].sort_by{ |f| File.mtime(f) }.last
      end
    end

    def local_repl_port
      @local_repl_port ||= begin
        ports_file = File.join(build_dir, 'repl_ports.txt')
        if File.exist?(ports_file)
          File.read(ports_file)
        else
          local_repl_port = TCPServer.new('localhost', 0).addr[1]
          File.open(ports_file, 'w') { |io| io.write(local_repl_port.to_s) }
          local_repl_port
        end
      end
    end

    # --------------------------------------------------------------------------
    # @!group Executing commands/tasks in the target's context
    # --------------------------------------------------------------------------

    # Executes a rake task of the target's Rakefile.
    #
    # If the target has a Gemfile that should be used, ensure it is installed.
    #
    # @param [String] task
    #        The rake task to invoke in the target's context.
    #
    # @return [Boolean] Whether or not invoking the rake task succeeded.
    #
    def rake(task)
      install_gemfile_if_necessary!

      command = "rake #{task}"
      command = "#{command} --trace" if App::VERBOSE
      command = "bundle exec #{command}" if use_gemfile?
      system(command)
    end

    # Executes a given command with the target path as the working-directory and
    # assigns the `environment_variables` to the command's environment.
    #
    # If the current process is running in verbose mode, a pseudo description of
    # the command is printed before executing the command.
    #
    # @param [String] command
    #        The command to execute.
    #
    # @return [Boolean] Whether or not the command exited with a succes status.
    #
    def system(command)
      system_proc = proc do
        env = environment_variables
        if App::VERBOSE
          env_description = env.map { |k, v| "#{k}='#{v}'" }.join(' ')
          puts "cd '#{@full_path}' && env #{env_description} #{command}"
        end

        Dir.chdir(@full_path) do
          super(env, command)
        end
      end

      if use_gemfile?
        Bundler.with_clean_env(&system_proc)
      else
        system_proc.call
      end
    end

    # @return [Hash] The current environment variables onto which the variables
    #         that describe the current host application are merged, which the
    #         target's build system depends on.
    #
    def environment_variables
      env = {
        "PWD" => @full_path,
        "RM_TARGET_SDK_VERSION" => @config.sdk_version,
        "RM_TARGET_DEPLOYMENT_TARGET" => @config.deployment_target,
        "RM_TARGET_XCODE_DIR" => @config.xcode_dir,
        "RM_TARGET_HOST_APP_NAME" => @config.name,
        "RM_TARGET_HOST_APP_VERSION" => @config.version,
        "RM_TARGET_HOST_APP_SHORT_VERSION" => @config.short_version,
        "RM_TARGET_HOST_APP_IDENTIFIER" => @config.identifier,
        "RM_TARGET_HOST_APP_SEED_ID" => @config.seed_id,
        "RM_TARGET_HOST_APP_PATH" => File.expand_path(@config.project_dir),
        "RM_TARGET_BUILD" => '1',
        "RM_TARGET_ARCHS" => @config.archs.inspect,
        "RM_TARGET_EMBED_DSYM" => @config.embed_dsym.inspect,
      }
      env["BUNDLE_GEMFILE"] = gemfile_path if use_gemfile?
      ENV.to_hash.merge(env).merge(@opts[:env] || {})
    end

    # --------------------------------------------------------------------------
    # @!group Bundler/Gemfile related methods
    # --------------------------------------------------------------------------

    # @return [String] The absolute path to the target's Gemfile.
    #
    def gemfile_path
      File.join(@full_path, 'Gemfile')
    end

    # @return [Boolean] Whether or not the user is building the host application
    #         in a Bundler context and if the target has a Gemfile of its own.
    #
    def use_gemfile?
      File.exist?(gemfile_path) && ENV['BUNDLE_GEMFILE']
    end

    # @return [Boolean] Whether or not the target's Gemfile has been installed.
    #
    def gemfile_installed?
      return @gemfile_installed unless @gemfile_installed.nil?
      @gemfile_installed = system("bundle check --no-color > /dev/null")
    end

    # In case the target has a Gemfile that should be used and it is not yet
    # installed, install it now.
    #
    # @return [void]
    #
    def install_gemfile_if_necessary!
      if use_gemfile? && !gemfile_installed?
        App.info 'Bundle', @full_path
        unless system("bundle install")
          App.fail "Failed to install the target's Gemfile."
        end
        @gemfile_installed = true
      end
    end
  end
end; end

require 'motion/project/target/framework_target'
require 'motion/project/target/extension_target'
require 'motion/project/target/watch_target'
