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

module Motion; module Project
  # Deprecated base command class, will be removed in RM v3.
  #
  # See the Motion::Command class in lib/motion/command.rb instead.
  #
  class Command < Motion::Command
    self.ignore_in_command_lookup = true

    class << self
      # This is lifted straight from CLAide, but adjusted slightly because
      # the Class#name method is overridden in the old (deprecated) API below.
      def command
        @command ||= __name__.split('::').last.gsub(/[A-Z]+[a-z]*/) do |part|
          part.downcase << '-'
        end[0..-2]
      end
      class << self
        alias_method :__name__, :name
      end

      def inherited(klass)
        warn "[!] Inheriting from `Motion::Project::Command' has been " \
             "deprecated, inherit from `Motion::Command' instead. " \
             "(Called from: #{caller.first})"
        super
      end

      # Override initializer to return a proxy that calls the instance with
      # the expected arguments when needed.
      #
      # Normal CLAide command classes are called with `Command#run`, whereas
      # these deprecated classes need to be called with `Command#run(argv)`.
      def new(argv)
        instance = super(argv)
        wrapper = lambda { instance.run(argv.remainder) }
        def wrapper.run; call; end # Call lambda which forwards to #run(argv)
        def wrapper.validate!; end # Old command has no notion of validation.
        wrapper
      end

      # ---------------------------------------------------------------------

      alias_method :name, :command
      def name=(command); self.command = command; end

      alias_method :help, :summary
      def help=(summary); self.summary = summary; end
    end

    def run(args)
      # To be implemented by subclasses.
    end
  end
end; end

# Now load plugins installed the old way.
#
# TODO deprecate in favor of RubyGems plugins?
Dir.glob(File.join(ENV['HOME'], 'Library/RubyMotion/command', '*.rb')).each { |x| require x }
