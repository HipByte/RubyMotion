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

module Motion; module Project;
  class Vendor
    include Rake::DSL if Rake.const_defined?(:DSL)

    def initialize(path, type, config, opts)
      @path = path.to_s
      @type = type
      @config = config
      @opts = opts
      @libs = []
      @bs_files = []
    end

    attr_reader :path, :libs, :bs_files, :opts

    def build(platform)
      App.info 'Build', @path
      send gen_method('build'), platform, @opts
      if @libs.empty?
        App.fail "Building vendor project `#{@path}' failed to create at least one `.a' library."
      end
    end

    def clean
      send gen_method('clean')
    end

    def build_static(platform, opts)
      Dir.chdir(@path) do
        build_dir = "build-#{platform}"

        libs = (opts.delete(:products) or Dir.glob('*.a'))
        source_files = (opts.delete(:source_files) or Dir.glob('**/*.{c,m,cpp,cxx,mm,h}'))
        cflags = (opts.delete(:cflags) or '')

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
          sh "#{compiler} #{cflags}  #{@config.cflags(platform, cplusplus)} -I. -include \"#{pch}\" -c \"#{srcfile}\" -o \"#{objfile}\""
        end

        if File.exist?(build_dir)
          libname = 'lib' + File.basename(@path) + '.a'
          Dir.chdir(build_dir) do
            objs = Dir.glob('**/*.o')
            FileUtils.rm_rf libname
            unless objs.empty?
              sh "#{@config.locate_binary('ar')} -rcs #{libname} #{objs.join(' ')}"
            end
          end
          libpath = File.join(build_dir, libname)
          libs << libpath if File.exist?(libpath)
        end

        headers = source_files.select { |p| File.extname(p) == '.h' }
        bs_files = []
        unless headers.empty?
          bs_file = File.basename(@path) + '.bridgesupport'
          if !File.exist?(bs_file) or headers.any? { |h| File.mtime(h) > File.mtime(bs_file) }
            bs_cflags = (opts.delete(:bridgesupport_cflags) or '')
            bs_exceptions = (opts.delete(:bridgesupport_exceptions) or [])
            @config.gen_bridge_metadata(headers, bs_file, bs_cflags, bs_exceptions)
          end
          bs_files << bs_file
        end

        @libs = libs.map { |x| File.expand_path(x) }
        @bs_files = bs_files.map { |x| File.expand_path(x) }
      end
    end

    def clean_static
      ['iPhoneSimulator', 'iPhoneOS'].each do |platform|
        build_dir = File.join(@path, "build-#{platform}")
        if File.exist?(build_dir)
          App.info 'Delete', build_dir
          FileUtils.rm_rf build_dir
        end
      end
    end

    XcodeBuildDir = '.build'
    def build_xcode(platform, opts)
      Dir.chdir(@path) do
        build_dir = "build-#{platform}"
        if !File.exist?(build_dir) || opts.delete(:force_rebuild)
          FileUtils.mkdir_p build_dir

          # Prepare Xcode project settings.
          xcodeproj = opts.delete(:xcodeproj) || begin
            projs = Dir.glob('*.xcodeproj')
            if projs.size != 1
              App.fail "Can't locate Xcode project file for vendor project #{@path}"
            end
            projs[0]
          end
          target = opts.delete(:target)
          scheme = opts.delete(:scheme)
          if target and scheme
            App.fail "Both :target and :scheme are provided"
          end
          configuration = opts.delete(:configuration) || 'Release'

          # Unset environment variables that could potentially make the build
          # to fail.
          %w{CC CXX CFLAGS CXXFLAGS LDFLAGS}.each { |f| ENV[f] &&= nil }
 
          # Build project into a build directory. We delete the build directory
          # each time because Xcode is too stupid to be trusted to use the
          # same build directory for different platform builds.
          xcode_build_dir = File.expand_path(XcodeBuildDir)
          rm_rf xcode_build_dir
          xcopts = ''
          xcopts << "-target \"#{target}\" " if target
          xcopts << "-scheme \"#{scheme}\" " if scheme
          sh "/usr/bin/xcodebuild -project \"#{xcodeproj}\" #{xcopts} -configuration \"#{configuration}\" -sdk #{platform.downcase}#{@config.sdk_version} #{@config.arch_flags(platform)} CONFIGURATION_BUILD_DIR=#{xcode_build_dir} IPHONEOS_DEPLOYMENT_TARGET=#{@config.deployment_target} build"

          # Copy .a files into the platform build directory.
          prods = opts.delete(:products)
          Dir.glob(File.join(XcodeBuildDir, '*.a')).each do |lib|
            next if prods and !prods.include?(File.basename(lib))
            lib = File.readlink(lib) if File.symlink?(lib)
            sh "/bin/cp \"#{lib}\" \"#{build_dir}\""
          end
        end

        # Generate the bridgesupport file if we need to.
        bs_file = File.expand_path(File.basename(@path) + '.bridgesupport')
        headers_dir = opts.delete(:headers_dir)
        if !File.exist?(bs_file) and headers_dir
          project_dir = File.expand_path(@config.project_dir)
          headers = Dir.glob(File.join(project_dir, headers_dir, '**/*.h'))
          bs_cflags = (opts.delete(:bridgesupport_cflags) or '')
          bs_exceptions = (opts.delete(:bridgesupport_exceptions) or [])
          @config.gen_bridge_metadata(headers, bs_file, bs_cflags, bs_exceptions)
        end

        @bs_files = Dir.glob('*.bridgesupport').map { |x| File.expand_path(x) }
        @libs = Dir.glob("#{build_dir}/*.a").map { |x| File.expand_path(x) }
      end
    end

    def clean_xcode
      Dir.chdir(@path) do
        [XcodeBuildDir, 'build-iPhoneOS', 'build-iPhoneSimulator'].each { |x| rm_rf x }
      end
    end

    private

    def gen_method(prefix)
      method = "#{prefix}_#{@type.to_s}".intern
      raise "Invalid vendor project type: #{@type}" unless respond_to?(method)
      method
    end
  end
end; end
