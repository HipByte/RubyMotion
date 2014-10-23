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

require 'motion/version'
require 'motion/error'

require 'rubygems'

$:.unshift File.expand_path('../../../vendor/CLAide/lib', __FILE__)
require 'claide'

module Motion
  # This will cause these errors to only show their message when raised, unless
  # the `--verbose` option is specified.
  class InformativeError
    include CLAide::InformativeError
  end
end

# Make text pretty (by adding bold ANSI codes) by default.
CLAide::Command.ansi_output = true

module Motion
  # ---------------------------------------------------------------------------
  # Base command class of RubyMotion
  # ---------------------------------------------------------------------------
  class Command < CLAide::Command
    require 'motion/command/account'
    require 'motion/command/activate'
    require 'motion/command/changelog'
    require 'motion/command/create'
    require 'motion/command/device_console'
    require 'motion/command/ri'
    require 'motion/command/support'
    require 'motion/command/update'

    self.abstract_command = true
    self.command = 'motion'
    self.plugin_prefix = 'motion'

    self.description = 'RubyMotion lets you develop native iOS and OS X ' \
                       'applications using the awesome Ruby language.'

    # TODO remove in RM 3.
    def self.command=(name)
      if name.include?(':')
        root = File.expand_path('../../../', __FILE__)
        external_caller = caller.find { |line| !line.start_with?(root) }
        warn "[!] Commands should no longer use colons to indicate their " \
             "own namespace. (Called from: #{external_caller})"
      end
      super
    end

    def self.options
      [
        ['--version', 'Show the version of RubyMotion'],
      ].concat(super)
    end

    module Pre
      path = '/Library/RubyMotionPre/lib/motion/version.rb'
      eval(File.read(path)) if File.exist?(path)
    end

    def self.run(argv)
      argv = CLAide::ARGV.new(argv)
      if argv.flag?('version')
        if defined?(Pre::Motion::Version)
          $stdout.puts "#{Motion::Version} (stable), #{Pre::Motion::Version} (pre-release)"
        else
          $stdout.puts Motion::Version
        end
        exit 0
      end
      super(argv)
    end

    #def self.report_error(exception)
      # TODO in case we ever want to report expections.
    #end

    protected

    def die(message)
      raise InformativeError, message
    end

    def need_root
      if Process.uid != 0
        die "You need to be root to run this command."
      end
    end

    def pager
      ENV['PAGER'] || '/usr/bin/less'
    end

    LicensePath = '/Library/RubyMotion/license.key'
    def read_license_key
      unless File.exist?(LicensePath)
        die "License file not present. Please activate RubyMotion with `motion activate' and try again."
      end
      File.read(LicensePath).strip
    end

    def guess_email_address
      require 'uri'
      # Guess the default email address from git.
      URI.escape(`git config --get user.email`.strip)
    end

    # -------------------------------------------------------------------------
    # Prettify overrides
    # -------------------------------------------------------------------------

    class BoldBanner < CLAide::Command::Banner
      def make_bold(text)
        ansi_output? ? "\e[1m#{text}\e[0m" : text
      end

      alias_method :prettify_command_in_usage_description, :make_bold
      alias_method :prettify_option_name, :make_bold
      alias_method :prettify_subcommand_name, :make_bold
    end

    def self.banner(ansi_output = false, banner_class = BoldBanner)
      super
    end

    class BoldHelp < CLAide::Help
      def prettify_error_message(message)
        ansi_output? ? "\e[1m#{message}\e[0m" : message
      end
    end

    def self.help!(error_message = nil, ansi_output = false, help_class = BoldHelp)
      super
    end
  end
end

# Now load the deprecated Motion::Project::Command class and plugins.
# TODO remove in RM-3.
require 'motion/project/command'
