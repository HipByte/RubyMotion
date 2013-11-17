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

require 'optparse'
require 'motion/project/app'
require 'motion/project/template'

module Motion; module Project
  class CreateCommand < Command
    self.name = 'create'
    self.help = 'Create a new project'

    DefaultTemplate = 'ios'

    def run(args)
      options = {
        :template_name => DefaultTemplate
      }

      optparse = OptionParser.new do |opt|
        opt.banner  = "Usage: motion create [OPTIONS] <app-name>"

        opt.separator '  Options:'
        opt.on('--template=<template_name>', 'Specify the template') do |name|
          options[:template_name] = name
        end

        template_names = Motion::Project::Template.all_templates.keys.map { |x| x == DefaultTemplate ? "#{x} (default)" : x }.sort.join(', ')
        opt.separator "  Available templates:"
        opt.separator "        #{template_names}"
      end

      begin
        optparse.parse!(args)
      rescue OptionParser::ParseError
        die $!.to_s
      end

      unless args.size == 1
        die(optparse.to_s)
      end

      app_name = args.pop
      Motion::Project::App.create(app_name, options[:template_name])
    end
  end
end; end
