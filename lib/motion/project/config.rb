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

require 'motion/project/app'

module Motion; module Project
  class Config
    include Rake::DSL if defined?(Rake) && Rake.const_defined?(:DSL)

    VARS = []

    def self.variable(*syms)
      syms.each do |sym|
        attr_accessor sym
        VARS << sym.to_s
      end
    end

    class Deps < Hash
      def []=(key, val)
        key = relpath(key)
        val = [val] unless val.is_a?(Array)
        val = val.map { |x| relpath(x) }
        super
      end

      def relpath(path)
        /^\./.match(path) ? path : File.join('.', path)
      end
    end

    variable :name, :files, :build_dir, :specs_dir, :resources_dirs, :motiondir

    # Internal only.
    attr_accessor :build_mode, :spec_mode, :distribution_mode, :dependencies,
      :template, :detect_dependencies, :exclude_from_detect_dependencies

    ConfigTemplates = {}

    def self.register(template)
      ConfigTemplates[template] = self
    end

    def self.make(template, project_dir, build_mode)
      klass = ConfigTemplates[template]
      unless klass
        $stderr.puts "Config template `#{template}' not registered"
        exit 1
      end
      config = klass.new(project_dir, build_mode)
      config.template = template
      config
    end

    def initialize(project_dir, build_mode)
      @project_dir = project_dir
      @files = Dir.glob(File.join(project_dir, 'app/**/*.rb'))
      @build_mode = build_mode
      @name = 'Untitled'
      @resources_dirs = [File.join(project_dir, 'resources')]
      @build_dir = File.join(project_dir, 'build')
      @specs_dir = File.join(project_dir, 'spec')
      @detect_dependencies = true
      @exclude_from_detect_dependencies = []
    end

    OSX_VERSION = `/usr/bin/sw_vers -productVersion`.strip.sub(/\.\d+$/, '').to_f

    def variables
      map = {}
      VARS.each do |sym|
        map[sym] =
          begin
            send(sym)
          rescue Exception
            'Error'
          end
      end
      map
    end

    def setup_blocks
      @setup_blocks ||= []
    end

    def setup
      if @setup_blocks
        @setup_blocks.each { |b| b.call(self) }
        @setup_blocks = nil
        validate
      end
      self
    end

    def unescape_path(path)
      path.gsub('\\', '')
    end

    def escape_path(path)
      path.gsub(' ', '\\ ')
    end

    def locate_binary(name)
      [File.join(xcode_dir, 'usr/bin'), '/usr/bin'].each do |dir|
        path = File.join(dir, name)
        return escape_path(path) if File.exist?(path)
      end
      App.fail "Can't locate binary `#{name}' on the system."
    end

    def validate
      # Do nothing, for now.
    end

    def supported_versions
      @supported_versions ||= Dir.glob(File.join(motiondir, 'data', template.to_s, '*')).select{|path| File.directory?(path)}.map do |path|
        File.basename path
      end
    end

    def resources_dir
      warn("`app.resources_dir' is deprecated; use `app.resources_dirs'");
      @resources_dirs.first
    end

    def resources_dir=(dir)
      warn("`app.resources_dir' is deprecated; use `app.resources_dirs'");
      @resources_dirs = [dir]
    end

    def build_dir
      unless File.directory?(@build_dir)
        tried = false
        begin
          FileUtils.mkdir_p(@build_dir)
        rescue Errno::EACCES
          raise if tried
          require 'digest/sha1'
          hash = Digest::SHA1.hexdigest(File.expand_path(project_dir))
          tmp = File.join(ENV['TMPDIR'], hash)
          App.warn "Cannot create build_dir `#{@build_dir}'. Check the permissions. Using a temporary build directory instead: `#{tmp}'"
          @build_dir = tmp
          tried = true
          retry
        end
      end
      @build_dir
    end

    def build_mode_name
      @build_mode.to_s.capitalize
    end

    def development?
      @build_mode == :development
    end

    def release?
      @build_mode == :release
    end

    def development
      yield if development?
    end

    def release
      yield if release?
    end

    def opt_level
      @opt_level ||= case @build_mode
        when :development; 0
        when :release; 3
        else; 0
      end
    end

    attr_reader :project_dir

    def project_file
      File.join(@project_dir, 'Rakefile')
    end

    def files_dependencies(deps_hash)
      res_path = lambda do |x|
        path = /^\.{0,2}\//.match(x) ? x : File.join('.', x)
        unless @files.flatten.include?(path)
          App.fail "Can't resolve dependency `#{path}'"
        end
        path
      end
      deps_hash.each do |path, deps|
        deps = [deps] unless deps.is_a?(Array)
        @dependencies[res_path.call(path)] = deps.map(&res_path)
      end
    end

    def file_dependencies(file)
      # memorize the calculated file dependencies in order to reduce the time
      # detecting file dependencies.
      # http://hipbyte.myjetbrains.com/youtrack/issue/RM-466
      @known_dependencies ||= {}
      @known_dependencies[file] ||= begin
        deps = @dependencies[file] || []
        deps = deps.map { |x| file_dependencies(x) }.flatten.uniq
        deps << file
        deps
      end
    end

    def ordered_build_files
      @ordered_build_files ||= begin
        @files.flatten.map { |file| file_dependencies(file) }.flatten.uniq
      end
    end

    def spec_core_files
      @spec_core_files ||= begin
        # Core library + core helpers.
        Dir.chdir(File.join(File.dirname(__FILE__), '..')) do
          (['spec.rb'] +
          Dir.glob(File.join('project', 'template', App.template.to_s, 'spec-helpers', '*.rb'))).
            map { |x| File.expand_path(x) }
        end
      end
    end

    def spec_files
      @spec_files ||= begin
        # Project helpers.
        helpers = Dir.glob(File.join(specs_dir, 'helpers', '**', '*.rb'))
        # Project specs.
        specs = Dir.glob(File.join(specs_dir, '**', '*.rb')) - helpers
        if files_filter = ENV['files']
          # Filter specs we want to run. A filter can be either the basename of a spec file or its path.
          files_filter = files_filter.split(',')
          files_filter.map! { |x| File.exist?(x) ? File.expand_path(x) : x }
          specs.delete_if { |x| [File.expand_path(x), File.basename(x, '.rb'), File.basename(x, '_spec.rb')].none? { |p| files_filter.include?(p) } }
        end
        spec_core_files + helpers + specs
      end
    end

    def motiondir
      @motiondir ||= File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
    end

    def bindir
      File.join(motiondir, 'bin')
    end

    def datadir(target=deployment_target)
      File.join(motiondir, 'data', template.to_s, target)
    end

    def strip_args
      ''
    end

    def print_crash_message
      $stderr.puts ''
      $stderr.puts '=' * 80
      $stderr.puts <<EOS
The application terminated. A crash report file may have been generated by the
system, use `rake crashlog' to open it. Use `rake debug=1' to restart the app
in the debugger.
EOS
      $stderr.puts '=' * 80
    end

    def clean_project
      paths = [self.build_dir]
      paths.concat(Dir.glob(self.resources_dirs.flatten.map{ |x| x + '/**/*.{nib,storyboardc,momd}' }))
      paths.each do |p|
        next if File.extname(p) == ".nib" && !File.exist?(p.sub(/\.nib$/, ".xib"))
        App.info 'Delete', p
        rm_rf p
        if File.exist?(p)
          # It can happen that because of file permissions a dir/file is not
          # actually removed, which can lead to confusing issues.
          App.fail "Failed to remove `#{p}'. Please remove this path manually."
        end
      end
    end
  end
end; end
