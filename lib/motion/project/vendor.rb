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

require 'pathname'

module Motion; module Project;
  class Vendor
    include Rake::DSL if Rake.const_defined?(:DSL)

    XcodeBuildDir = '.build'
    XCODEBUILD_PATH = '/usr/bin/xcodebuild'

    def initialize(path, type, config, opts)
      @path = path.to_s
      @type = type.to_sym
      @config = config
      @opts = opts
      @libs = []
      @bs_files = []
    end

    attr_reader :path, :libs, :bs_files, :opts

    def build(platform)
      Dir.chdir(@path) do
        send(gen_method('build'), platform)
      end
    end

    # This removes the various build dirs that may exist in either `:static` or
    # `:xcode` vendored projects.
    #
    # In the case of an `:xcode` vendored project, it will first run
    # `xcodebuild clean` with the exact same options as it was build with. This
    # to ensure that cached build artefacts that are outside of the build dir
    # are cleaned up as well. For instance those in:
    # `$TMPDIR/../C/com.apple.DeveloperTools/*/Xcode/SharedPrecompiledHeaders`.
    #
    # @param [Array<String>] platforms
    #        The platform identifiers for which to perform a clean.
    #
    # @return [void]
    #
    # @todo Seeing as this method gets the exact platforms to clean for, we can
    #       get rid of the list of all build dirs and ask for the exact build
    #       dir from the `config`.
    #
    def clean(platforms)
      if @type == :xcode && File.exist?(@path)
        Dir.chdir(@path) do
          platforms.each do |platform|
            path = relative_path("./#{xcodeproj_path}")
            App.info 'Clean', "#{path} for platform `#{platform}'"
            xcodebuild(platform, 'clean')
          end
        end
      end
      [XcodeBuildDir, 'build', 'build-iPhoneSimulator', 'build-iPhoneOS', 'build-MacOSX'].each do |build_dir|
        build_dir = File.join(@path, build_dir)
        if File.exist?(build_dir)
          App.info 'Delete', relative_path(build_dir)
          FileUtils.rm_rf build_dir
          if File.exist?(build_dir)
            # It can happen that because of file permissions a dir/file is not
            # actually removed, which can lead to confusing issues.
            App.fail "Failed to remove `#{relative_path(build_dir)}'. Please remove this path manually."
          end
        end
      end
    end

    def build_static(platform)
      App.info 'Build', @path
      build_dir = build_dir(platform)
      libs = (@opts[:products] or Dir.glob('*.a'))
      source_files = (@opts[:source_files] or ['**/*.{c,m,cpp,cxx,mm,h}']).map { |pattern| Dir.glob(pattern) }.flatten
      cflags = (@opts[:cflags] or '')

      source_files.each do |srcfile|
        objfile = File.join(build_dir, srcfile + '.o')
        next if File.exist?(objfile) and File.mtime(objfile) > File.mtime(srcfile)
        cplusplus = false
        compiler =
          case File.extname(srcfile)
            when '.c', '.m'
              @config.locate_compiler(platform, 'clang', 'gcc')
            when '.cpp', '.cxx', '.mm'
              cplusplus = true
              @config.locate_compiler(platform, 'clang++', 'g++')
            else
              # Not a valid source file, skip.
              next
          end

        pch = File.join(build_dir, File.basename(@path) + '.pch')
        unless File.exist?(pch)
          FileUtils.mkdir_p File.dirname(pch)
          File.open(pch, 'w') do |io|
            case platform
              when "MacOSX"
                header =<<EOS
#ifdef __OBJC__
#  import <Cocoa/Cocoa.h>
#endif
EOS
              when /^iPhone/
                header =<<EOS
#ifdef __OBJC__
#  import <UIKit/UIKit.h>
#endif
EOS
              else
                App.fail "Unknown platform : #{platform}"
            end
            io.puts header
          end
        end

        App.info 'Compile', File.join(@path, srcfile)
        FileUtils.mkdir_p File.dirname(objfile)
        # Always append the user's clfags *after* ours, so that the user gets a
        # chance to override settings that we set. E.g. `-fno-modules`.
        sh "#{compiler} #{@config.cflags(platform, cplusplus)} #{cflags} -I. -include \"#{pch}\" -c \"#{srcfile}\" -o \"#{objfile}\""
      end

      if File.exist?(build_dir)
        libname = 'lib' + File.basename(@path) + '.a'
        Dir.chdir(build_dir) do
          objs = Dir.glob('**/*.o')
          FileUtils.rm_rf libname
          unless objs.empty?
            sh "#{@config.locate_binary('ar')} -rc \"#{libname}\" #{objs.join(' ')}"
            sh "/usr/bin/ranlib \"#{libname}\""
          end
        end
        libpath = File.join(build_dir, libname)
        libs << libpath if File.exist?(libpath)
      end

      @libs = libs.map { |x| File.expand_path(x) }
      if @libs.empty?
        App.fail "Building vendor project `#{@path}' failed to create at least one `.a' library."
      end

      headers = source_files.select { |p| File.extname(p) == '.h' }
      bs_files = []
      unless headers.empty?
        bs_file = bridgesupport_build_path
        if !File.exist?(bs_file) or headers.any? { |h| File.mtime(h) > File.mtime(bs_file) }
          FileUtils.mkdir_p File.dirname(bs_file)
          bs_cflags = (@opts[:bridgesupport_cflags] or cflags)
          bs_exceptions = (@opts[:bridgesupport_exceptions] or [])
          @config.gen_bridge_metadata(platform, headers, bs_file, bs_cflags, bs_exceptions)
        end
        bs_files << bs_file
      end
      @bs_files = bs_files.map { |x| File.expand_path(x) }
    end

    def build_xcode(platform)
      # Validate common build directory.
      if !File.writable?(Dir.pwd)
        $stderr.puts "Cannot write into the `#{Dir.pwd}' directory, please check permissions and try again."
        exit 1
      end

      build_dir = build_dir(platform)
      if !File.exist?(build_dir) or Dir.glob('**/*').any? { |x| File.mtime(x) > File.mtime(build_dir) }
        FileUtils.mkdir_p build_dir

        xcodebuild(platform, 'build')

        # Copy .a files into the platform build directory.
        prods = @opts[:products]
        Dir.glob(File.join(XcodeBuildDir, '*.a')).each do |lib|
          next if prods and !prods.include?(File.basename(lib))
          lib = File.readlink(lib) if File.symlink?(lib)
          sh "/bin/cp \"#{lib}\" \"#{build_dir}\""
        end

        `/usr/bin/touch \"#{build_dir}\"`
      end

      @libs = Dir.glob("#{build_dir}/*.a").map { |x| File.expand_path(x) }
      if @libs.empty?
        App.fail "Building vendor project `#{@path}' failed to create at least one `.a' library."
      end

      # Generate the bridgesupport file if we need to.
      bs_file = bridgesupport_build_path
      headers_dir = @opts[:headers_dir]
      if headers_dir
        # Dir.glob does not traverse symlinks with `**`, using this pattern
        # will at least traverse symlinks one level down.
        headers = Dir.glob(File.join(project_dir, headers_dir, '**{,/*/**}/*.h'))
        if !File.exist?(bs_file) or headers.any? { |x| File.mtime(x) > File.mtime(bs_file) }
          FileUtils.mkdir_p File.dirname(bs_file)
          bs_cflags = (@opts[:bridgesupport_cflags] or @opts[:cflags] or '')
          bs_exceptions = (@opts[:bridgesupport_exceptions] or [])
          @config.gen_bridge_metadata(platform, headers, bs_file, bs_cflags, bs_exceptions)
        end
      end
      @bs_files = Dir.glob("#{build_dir}/*.bridgesupport").map { |x| File.expand_path(x) }
    end

    private

    def build_dir(platform)
      @build_dir ||= begin
        path = "build-#{platform}"
        unless File.writable?(Dir.pwd)
          path = File.join(Builder.common_build_dir, @path, path)
        end
        path
      end
    end

    def project_dir
      File.expand_path(@config.project_dir)
    end

    def gen_method(prefix)
      method = "#{prefix}_#{@type.to_s}".intern
      raise "Invalid vendor project type: #{@type}" unless respond_to?(method)
      method
    end

    # First check if an explicit metadata file exists and, if so, write
    # the new file to that same location. Otherwise fall back to the
    # platform-specific build dir.
    def bridgesupport_build_path
      bs_file = File.basename(@path) + '.bridgesupport'
      unless File.exist?(bs_file)
        bs_file = File.join(Builder.common_build_dir, File.expand_path(@path) + '.bridgesupport')
      end
      bs_file
    end

    def relative_path(path)
      if ENV['RM_TARGET_HOST_APP_PATH']
        Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(ENV['RM_TARGET_HOST_APP_PATH'])).to_s
      else
        path
      end
    end

    def xcodeproj_path
      @xcodeproj_path ||= begin
        unless path = (@opts[:xcodeproj] || Dir.glob('*.xcodeproj')[0])
          App.fail "Can't locate Xcode project file for vendor project #{@path}"
        end
        path
      end
    end

    def xcodeproj_settings
      details = {
        :xcodeproj => xcodeproj_path,
        :configuration => @opts[:configuration] || 'Release'
      }

      target = @opts[:target]
      scheme = @opts[:scheme]
      if target and scheme
        App.fail "Both :target and :scheme are provided"
      end
      details[:target] = target if target
      details[:scheme] = scheme if scheme

      details
    end

    def xcodebuild(platform, action)
      settings = xcodeproj_settings

      # Unset environment variables that could potentially make the build
      # to fail.
      %w{CC CXX CFLAGS CXXFLAGS LDFLAGS}.each { |f| ENV[f] &&= nil }

      # Build project into a build directory. We delete the build directory
      # each time because Xcode is too stupid to be trusted to use the
      # same build directory for different platform builds.
      xcode_build_dir = File.expand_path(XcodeBuildDir)
      rm_rf xcode_build_dir
      xcopts = ''
      xcopts << "-target \"#{settings[:target]}\" " if settings[:target]
      xcopts << "-scheme \"#{settings[:scheme]}\" " if settings[:scheme]
      xcconfig = "CONFIGURATION_BUILD_DIR=\"#{xcode_build_dir}\" "
      case platform
      when "MacOSX"
        xcconfig << "MACOSX_DEPLOYMENT_TARGET=#{@config.deployment_target} "
      when /^iPhone/
        xcconfig << "IPHONEOS_DEPLOYMENT_TARGET=#{@config.deployment_target} "
      else
        App.fail "Unknown platform : #{platform}"
      end

      invoke_xcodebuild("-project '#{settings[:xcodeproj]}' #{xcopts} -configuration '#{settings[:configuration]}' -sdk #{platform.downcase}#{@config.sdk_version} #{@config.arch_flags(platform)} #{xcconfig} #{action}")
    end

    def invoke_xcodebuild(cmd)
      command = "#{XCODEBUILD_PATH} #{cmd}"
      unless App::VERBOSE
        command << " 2>&1 | env RM_XCPRETTY_PRINTER_PROJECT_ROOT='#{project_dir}' '#{File.join(@config.motiondir, 'vendor/XCPretty/bin/xcpretty')}' --printer '#{File.join(@config.motiondir, 'lib/motion/project/vendor/xcpretty_printer.rb')}'"
      end
      sh command
    end
  end
end; end
