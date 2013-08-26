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

module Motion; module Project
  class Command
    class << self
      attr_accessor :name
      attr_accessor :help
    end

    Commands = []
    def self.inherited(klass)
      Commands << klass if self == Command
    end

    def self.main(args)
      arg = args.shift
      case arg
        when '-h', '--help'
          usage
        when '-v', '--version'
          $stdout.puts Motion::Version
          exit 1
        when /^-/
          $stderr.puts "Unknown option: #{arg}"
          exit 1
      end
      command = Commands.find { |command| command.name == arg }
      usage unless command
      command.new.run(args)
    end

    def self.usage
      $stderr.puts 'Usage:'
      $stderr.puts "  motion [-h, --help]"
      $stderr.puts "  motion [-v, --version]"
      $stderr.puts "  motion <command> [<args...>]"
      $stderr.puts ''
      $stderr.puts 'Commands:'
      Commands.each do |command|
        $stderr.puts "  #{command.name}".ljust(20) + command.help
      end
      exit 1
    end

    def run(args)
      # To be implemented by subclasses.
    end
 
    def die(*msg)
      $stderr.puts msg
      exit 1
    end

    def need_root
      if Process.uid != 0
        die "You need to be root to run this command."
      end
    end

    LicensePath = '/Library/RubyMotion/license.key'
    def read_license_key
      unless File.exist?(LicensePath)
        die "License file not present. Please activate RubyMotion with `motion activate' and try again."
      end
      File.read(LicensePath).strip
    end

    def guess_email_address
      # Guess the default email address from git.
      URI.escape(`git config --get user.email`.strip)
    end
  end
end; end
