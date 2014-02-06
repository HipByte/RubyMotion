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

require 'motion/project/app'
require 'motion/project/template'

module Motion; class Command
  class Create < Command
    DefaultTemplate = 'ios'

    def self.all_templates
      Motion::Project::Template.all_templates.keys
    end

    def self.templates_description
      all_templates.map do |x|
        x == DefaultTemplate ? "#{x} (default)" : x
      end.join(', ')
    end

    self.summary = 'Create a new project.'

    # Override getter so that we fetch the template names as late as possible.
    def self.description
      "Create a new RubyMotion project from one of the " \
      "following templates: #{templates_description}."
    end

    self.arguments = 'APP-NAME'

    def self.options
      [
        ['--template=[NAME|URL]', "A built-in template or from a file/git URL"],
      ].concat(super)
    end

    def initialize(argv)
      @template = argv.option('template') || DefaultTemplate
      @app_name = argv.shift_argument
      super
    end

    def validate!
      super
      help! "A name for the new project is required." unless @app_name
      # TODO This needs to take into account external templates (e.g. from git
      #      or a local path.)
      #unless self.class.all_templates.include?(@template)
        #help! "Invalid template specified `#{@template}'."
      #end
    end

    def run
      Motion::Project::App.create(@app_name, @template)
    end
  end
end; end
