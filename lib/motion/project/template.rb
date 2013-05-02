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
  class Template
    # for ERB
    attr_reader :name

    Paths = [
      File.expand_path(File.join(__FILE__, '../template')),
      File.expand_path(File.join(ENV['HOME'], 'Library/RubyMotion/template'))
    ]

    def initialize(app_name, template_name)
      @name = @app_name = app_name
      @template_name = template_name.to_s

      @template_directory = Paths.map { |x| File.join(x, @template_name) }.find { |x| File.exist?(x) }
      unless @template_directory
        $stderr.puts "Cannot find template `#{@template_name}' in #{Paths.join(' or ')}"
        exit 1
      end

      unless app_name.match(/^[\w\s-]+$/)
        $stderr.puts "Invalid app name"
        exit 1
      end

      if File.exist?(app_name)
        $stderr.puts "Directory `#{app_name}' already exists"
        exit 1
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
      template_files = File.join(template_directory, 'files')
      Dir.glob(File.join(template_files, "**/")).each do |dir|
        dir.sub!("#{template_files}/", '')
        FileUtils.mkdir_p(dir) if dir.length > 0
      end
    end

    def create_files
      template_files = File.join(template_directory, 'files')
      Dir.glob(File.join(template_files, "**/*"), File::FNM_DOTMATCH).each do |src|
        dest = src.sub("#{template_files}/", '')
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
end; end
