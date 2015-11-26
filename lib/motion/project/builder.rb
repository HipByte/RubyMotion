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

require 'thread'
require 'motion/project/paralel_builder'
require 'motion/project/dependency'
require 'motion/project/experimental_dependency'

module Motion; module Project;
  class Builder
    include Rake::DSL if Object.const_defined?(:Rake) && Rake.const_defined?(:DSL)

    def build(config, platform, opts)
      datadir = config.datadir
      unless File.exist?(File.join(datadir, platform))
        $stderr.puts "This version of RubyMotion does not support `#{platform}'"
        exit 1
      end
      archs = config.archs[platform].uniq

      static_library = opts.delete(:static)

      ruby = File.join(config.bindir, 'ruby')
      @nfd = File.join(config.bindir, 'nfd')

      if config.spec_mode and (config.spec_files - config.spec_core_files).empty?
        App.fail "No spec files in `#{config.specs_dir}'"
      end

      config.resources_dirs.flatten!
      config.resources_dirs.uniq!

      # Locate SDK and compilers.
      sdk = config.sdk(platform)
      cc = config.locate_compiler(platform, 'clang')
      cxx = config.locate_compiler(platform, 'clang++')

      build_dir = File.join(config.versionized_build_dir(platform))
      App.info 'Build', build_dir

      # Prepare the list of BridgeSupport files needed.
      bs_files = config.bridgesupport_files

      # Build vendor libraries.
      vendor_libs = []
      config.vendor_projects.each do |vendor_project|
        vendor_project.build(platform)
        vendor_libs.concat(vendor_project.libs)
        bs_files.concat(vendor_project.bs_files)
      end

      # Prepare embedded and external frameworks BridgeSupport files
      if config.respond_to?(:embedded_frameworks) && config.respond_to?(:external_frameworks)
        embedded_frameworks = config.embedded_frameworks.map { |x| File.expand_path(x) }
        external_frameworks = config.external_frameworks.map { |x| File.expand_path(x) }
        (embedded_frameworks + external_frameworks).each do |path|
          headers = Dir.glob(File.join(path, 'Headers/**/*.h'))
          bs_file = File.join(Builder.common_build_dir, File.expand_path(path) + '.bridgesupport')
          if !File.exist?(bs_file) or File.mtime(path) > File.mtime(bs_file)
            FileUtils.mkdir_p(File.dirname(bs_file))
            config.gen_bridge_metadata(platform, headers, bs_file, '', [])
          end
          bs_files << bs_file
        end
      else
        embedded_frameworks = external_frameworks = []
      end

      # Build targets
      target_frameworks = []
      unless config.targets.empty?
        config.targets.each do |target|
          target.build(platform)
        end

        # Prepare target frameworks
        config.targets.select { |t| t.type == :framework && t.load? }.each do |target|
          target_frameworks << target.framework_name
        end
      end

      # Build object files.
      objs_build_dir = File.join(build_dir, 'objs')
      FileUtils.mkdir_p(objs_build_dir)
      any_obj_file_built = false
      project_files = Dir.glob("**/*.rb").map{ |x| File.expand_path(x) }
      is_default_archs = (archs == config.default_archs[platform])
      rubyc_bs_flags = bs_files.map { |x| "--uses-bs \"" + x + "\" " }.join(' ')

      @compiler = []
      build_file = Proc.new do |files_build_dir, path, job|
        rpath = path
        path = File.expand_path(path)
        if is_default_archs && !project_files.include?(path)
          files_build_dir = File.expand_path(File.join(Builder.common_build_dir, files_build_dir))
        end
        obj = File.join(files_build_dir, "#{path}.o")
        should_rebuild = (!File.exist?(obj) \
            or File.mtime(path) > File.mtime(obj) \
            or File.mtime(ruby) > File.mtime(obj))

        # Generate or retrieve init function.
        init_func = should_rebuild ? "MREP_#{`/usr/bin/uuidgen`.strip.gsub('-', '')}" : `#{config.locate_binary('nm')} \"#{obj}\"`.scan(/T\s+_(MREP_.*)/)[0][0]

        if should_rebuild
          App.info 'Compile', rpath
          FileUtils.mkdir_p(File.dirname(obj))
          arch_objs = []
          archs.each do |arch|
            # Locate arch kernel.
            kernel = File.join(datadir, platform, "kernel-#{arch}.bc")
            raise "Can't locate kernel file" unless File.exist?(kernel)

            # Assembly.
            compiler_exec_arch = case arch
              when /^arm/
                arch == 'arm64' ? 'x86_64' : 'i386'
              else
                arch
            end
            asm_extension = platform == 'AppleTVOS' ? 'bc' : 's'
            asm = File.join(files_build_dir, "#{path}.#{arch}.#{asm_extension}")
            @compiler[job] ||= {}
            @compiler[job][arch] ||= IO.popen("/usr/bin/env VM_PLATFORM=\"#{platform}\" VM_KERNEL_PATH=\"#{kernel}\" VM_OPT_LEVEL=\"#{config.opt_level}\" /usr/bin/arch -arch #{compiler_exec_arch} #{ruby} #{rubyc_bs_flags} --emit-llvm-fast \"\"", "r+")
            @compiler[job][arch].puts "#{asm}\n#{init_func}\n#{path}"
            @compiler[job][arch].gets # wait to finish compilation

            if !File.exists?(asm)
              App.fail "File '#{rpath}' failed to compile"
            end

            # Object
            arch_obj = File.join(files_build_dir, "#{path}.#{arch}.o")

            if platform == 'AppleTVOS'
              @dummy_object_file ||= begin
                src_path = '/tmp/__dummy_object_file__.c'
                obj_path = '/tmp/__dummy_object_file__.o'
                File.open(src_path, 'w') { |io| io.puts "static int foo(void) { return 42; }" }
                sh "#{cc} -c #{src_path} -o #{obj_path} -arch armv7k -fembed-bitcode"
                obj_path
              end
              sh "#{cxx} #{config.cflag_version_min(platform)} -fexceptions -c -arch #{arch} \"#{asm}\" -o \"#{arch_obj}\""
            else
              sh "#{cc} #{config.cflag_version_min(platform)} -fexceptions -c -arch #{arch} \"#{asm}\" -o \"#{arch_obj}\""
            end

            [asm].each { |x| File.unlink(x) } unless ENV['keep_temps']
            arch_objs << arch_obj
          end

          # Assemble fat binary.
          arch_objs_list = arch_objs.map { |x| "\"#{x}\"" }.join(' ')
          sh "/usr/bin/lipo -create #{arch_objs_list} -output \"#{obj}\""

          any_obj_file_built = true
        end

        [obj, init_func]
      end

      # Resolve file dependencies.
      if config.detect_dependencies == true
        klass = ENV['experimental_dependency'] ? ExperimentalDependency : Dependency
        config.dependencies = klass.new(config.files - config.exclude_from_detect_dependencies, config.dependencies).run
      end

      parallel = ParallelBuilder.new(objs_build_dir, build_file)
      parallel.files = config.ordered_build_files
      parallel.files += config.spec_files if config.spec_mode
      parallel.run

      # terminate compiler process
      @compiler.each do |item|
        next unless item
        item.each do |k, v|
          v.puts "quit"
        end
      end

      objs = app_objs = parallel.objects
      spec_objs = []
      if config.spec_mode
        app_objs = objs[0...config.ordered_build_files.size]
        spec_objs = objs[-(config.spec_files.size)..-1]
      end

      FileUtils.touch(objs_build_dir) if any_obj_file_built

      # Generate init file.
      init_txt = <<EOS
#import <Foundation/Foundation.h>

extern "C" {
    void ruby_sysinit(int *, char ***);
    void ruby_init(void);
    void ruby_init_loadpath(void);
    void ruby_script(const char *);
    void ruby_set_argv(int, char **);
    void rb_vm_init_compiler(void);
    void rb_vm_init_jit(void);
    void rb_vm_aot_feature_provide(const char *, void *);
    void *rb_vm_top_self(void);
    void rb_define_global_const(const char *, void *);
    void rb_rb2oc_exc_handler(void);
    void rb_exit(int);
EOS
      config.custom_init_funcs.each do |init_func|
        init_txt << "void #{init_func}(void);\n"
      end
      app_objs.each do |_, init_func|
        init_txt << "void #{init_func}(void *, void *);\n"
      end
      init_txt << <<EOS
}

extern "C"
void
RubyMotionInit(int argc, char **argv)
{
    static bool initialized = false;
    if (!initialized) {
	ruby_init();
	ruby_init_loadpath();
        if (argc > 0) {
	    const char *progname = argv[0];
	    ruby_script(progname);
	}
#if !__LP64__
	try {
#endif
	    void *self = rb_vm_top_self();
EOS
      init_txt << config.define_global_env_txt

      if !config.targets.empty? and !target_frameworks.empty?
        init_txt << "NSString *frameworks_path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @\"Frameworks\"];\n"
        target_frameworks.each do |framework|
          init_txt << "[[NSBundle bundleWithPath: [frameworks_path stringByAppendingPathComponent: @\"#{framework}\"]] load];\n"
        end
      end

      config.custom_init_funcs.each do |init_func|
        init_txt << "#{init_func}();\n"
      end
      app_objs.each do |_, init_func|
        init_txt << "#{init_func}(self, 0);\n"
      end
      init_txt << <<EOS
#if !__LP64__
	}
	catch (...) {
	    rb_rb2oc_exc_handler();
	}
#endif
	initialized = true;
    }
}
EOS

      # Compile init file.
      init = File.join(objs_build_dir, 'init.mm')
      init_o = File.join(objs_build_dir, 'init.o')
      if !(File.exist?(init) and File.exist?(init_o) and File.read(init) == init_txt)
        File.open(init, 'w') { |io| io.write(init_txt) }
        sh "#{cxx} \"#{init}\" #{config.cflags(platform, true)} -c -o \"#{init_o}\""
      end

      librubymotion = File.join(datadir, platform, 'librubymotion-static.a')
      if static_library
        # Create a static archive with all object files + the runtime.
        lib = File.join(config.versionized_build_dir(platform), config.name + '.a')
        App.info 'Create', lib
        kernel = File.join(datadir, platform, "kernel.o")
        objs_list = objs.map { |path, _| path }.unshift(init_o, *config.frameworks_stubs_objects(platform)).map { |x| "\"#{x}\"" }.join(' ')
        sh "/usr/bin/libtool -static \"#{librubymotion}\" \"#{kernel}\" #{objs_list} -o \"#{lib}\""
        return lib
      end

      # Generate main file.
      main_txt = config.main_cpp_file_txt(spec_objs)

      # Compile main file.
      main = File.join(objs_build_dir, 'main.mm')
      main_o = File.join(objs_build_dir, 'main.o')
      if !(File.exist?(main) and File.exist?(main_o) and File.read(main) == main_txt)
        File.open(main, 'w') { |io| io.write(main_txt) }
        sh "#{cxx} \"#{main}\" #{config.cflags(platform, true)} -c -o \"#{main_o}\""
      end

      # Prepare bundle.
      bundle_path = config.app_bundle(platform)
      unless File.exist?(bundle_path)
        App.info 'Create', bundle_path
        FileUtils.mkdir_p(bundle_path)
      end

      # Link executable.
      main_exec = config.app_bundle_executable(platform)
      unless File.exist?(File.dirname(main_exec))
        App.info 'Create', File.dirname(main_exec)
        FileUtils.mkdir_p(File.dirname(main_exec))
      end
      main_exec_created = false
      if !File.exist?(main_exec) \
          or File.mtime(config.project_file) > File.mtime(main_exec) \
          or objs.any? { |path, _| File.mtime(path) > File.mtime(main_exec) } \
	  or File.mtime(main_o) > File.mtime(main_exec) \
          or vendor_libs.any? { |lib| File.mtime(lib) > File.mtime(main_exec) } \
          or File.mtime(librubymotion) > File.mtime(main_exec)
        App.info 'Link', main_exec
        framework_search_paths = (config.framework_search_paths + (embedded_frameworks + external_frameworks).map { |x| File.dirname(x) }).uniq.map { |x| "-F '#{File.expand_path(x)}'" }.join(' ')
        frameworks = (config.frameworks_dependencies + (embedded_frameworks + external_frameworks).map { |x| File.basename(x, '.framework') }).map { |x| "-framework #{x}" }.join(' ')
        weak_frameworks = config.weak_frameworks.map { |x| "-weak_framework #{x}" }.join(' ')
        vendor_libs = config.vendor_projects.inject([]) do |libs, vendor_project|
          libs << vendor_project.libs.map { |x|
            (vendor_project.opts[:force_load] ? '-force_load ' : '-ObjC ') + "\"#{x}\""
          }
        end.join(' ')
        linker_option = begin
          m = config.deployment_target.match(/(\d+)/)
          if m[0].to_i < 7
            "-stdlib=libstdc++"
          end
        end || ""
        objs_list = objs.map { |path, _| path }.unshift(init_o, main_o, *config.frameworks_stubs_objects(platform))
        # Instead of potentially passing hundreds of arguments to the `clang++`
        # command, which can lead to a 'too many arguments' error, we list them
        # in a temp file and pass that to the command.
        require 'tempfile'
        objs_file = Tempfile.new('linker-objs-list')
        objs_list.each { |obj| objs_file.puts(obj) }
        objs_file.close # flush
        kernel = File.join(datadir, platform, "kernel.o")
        sh "#{cxx} -o \"#{main_exec}\" \"#{kernel}\" -filelist \"#{objs_file.path}\" #{config.ldflags(platform)} -L#{File.join(datadir, platform)} -lrubymotion-static -lobjc -licucore #{linker_option} #{framework_search_paths} #{frameworks} #{weak_frameworks} #{config.libs.join(' ')} #{vendor_libs}"
        main_exec_created = true

        # Change the install name of embedded frameworks.
        embedded_frameworks.each do |path|
          res = `/usr/bin/otool -L \"#{main_exec}\"`.scan(/(.*#{File.basename(path)}.*)\s\(/)
          if res and res[0] and res[0][0]
            old_path = res[0][0].strip
            if platform == "MacOSX"
              exec_path = "@executable_path/../Frameworks/"
            else
              exec_path = "@executable_path/Frameworks/"
            end
            new_path = exec_path + old_path.scan(/#{File.basename(path)}.*/)[0]
            sh "/usr/bin/install_name_tool -change \"#{old_path}\" \"#{new_path}\" \"#{main_exec}\""
          else
            App.warn "Cannot locate and fix install name path of embedded framework `#{path}' in executable `#{main_exec}', application might not start"
          end
        end
      end

      # Create bundle/PkgInfo.
      bundle_pkginfo = File.join(bundle_path, 'PkgInfo')
      if !File.exist?(bundle_pkginfo) or File.mtime(config.project_file) > File.mtime(bundle_pkginfo)
        App.info 'Create', bundle_pkginfo
        File.open(bundle_pkginfo, 'w') { |io| io.write(config.pkginfo_data) }
      end

      # Compile IB resources.
      config.resources_dirs.each do |dir|
        if File.exist?(dir)
          ib_resources = []
          ib_resources.concat((Dir.glob(File.join(dir, '**', '*.xib')) + Dir.glob(File.join(dir, '*.lproj', '*.xib'))).map { |xib| [xib, xib.sub(/\.xib$/, '.nib')] })
          ib_resources.concat(Dir.glob(File.join(dir, '**', '*.storyboard')).map { |storyboard| [storyboard, storyboard.sub(/\.storyboard$/, '.storyboardc')] })
          ib_resources.each do |src, dest|
            if !File.exist?(dest) or File.mtime(src) > File.mtime(dest)
              App.info 'Compile', src
              sh "'#{File.join(config.xcode_dir, '/usr/bin/ibtool')}' --compile \"#{dest}\" \"#{src}\""
            end
          end
        end
      end

      preserve_resources = []

      # Compile Asset Catalog bundles.
      preserve_resources.concat(compile_asset_bundles(config, platform))

      # Compile CoreData Model resources and SpriteKit atlas files.
      config.resources_dirs.each do |dir|
        if File.exist?(dir)
          Dir.glob(File.join(dir, '*.xcdatamodeld')).each do |model|
            momd = model.sub(/\.xcdatamodeld$/, '.momd')
            if !File.exist?(momd) or File.mtime(model) > File.mtime(momd)
              App.info 'Compile', model
              model = File.expand_path(model) # momc wants absolute paths.
              momd = File.expand_path(momd)
              sh "\"#{App.config.xcode_dir}/usr/bin/momc\" \"#{model}\" \"#{momd}\""
            end
          end
          if cmd = config.spritekit_texture_atlas_compiler
            Dir.glob(File.join(dir, '*.atlas')).each do |atlas|
              if File.directory?(atlas)
                App.info 'Compile', atlas
                sh "\"#{cmd}\" \"#{atlas}\" \"#{bundle_path}\""
              end
            end
          end
        end
      end

      # Copy embedded frameworks.
      unless embedded_frameworks.empty?
        app_frameworks = File.join(config.app_bundle(platform), 'Frameworks')
        FileUtils.mkdir_p(app_frameworks)
        embedded_frameworks.each do |src_path|
          dest_path = File.join(app_frameworks, File.basename(src_path))
          if !File.exist?(dest_path) or File.mtime(src_path) > File.mtime(dest_path)
            App.info 'Copy', src_path
            FileUtils.cp_r(src_path, dest_path)
          end
        end
      end

      # Copy target products
      unless config.targets.empty?
        config.targets.each do |target|
          target.copy_products(platform)
        end
      end

      # Create bundle/Info.plist.
      generate_info_plist(config, platform)

      # Copy resources, handle subdirectories.
      app_resources_dir = config.app_resources_dir(platform)
      FileUtils.mkdir_p(app_resources_dir)
      reserved_app_bundle_files = [
        '_CodeSignature/CodeResources', 'CodeResources', 'embedded.mobileprovision',
        'Info.plist', 'PkgInfo',
        convert_filesystem_encoding(config.name)
      ]
      resources_exclude_extnames = ['.xib', '.storyboard', '.xcdatamodeld',
                                    '.atlas', '.xcassets', '.strings']
      resources_paths = []
      config.resources_dirs.each do |dir|
        if File.exist?(dir)
          resources_paths << Dir.chdir(dir) do
            Dir.glob('**{,/*/**}/*').reject do |x|
              # Find files with extnames to exclude or files inside bundles to
              # exclude (e.g. xcassets).
              File.extname(x) == '.lproj' ||
                resources_exclude_extnames.include?(File.extname(x)) ||
                  resources_exclude_extnames.include?(File.extname(x.split('/').first))
            end.map { |file| File.join(dir, file) }
          end
        end
      end
      resources_paths.flatten!
      resources_paths.each do |res_path|
        res = path_on_resources_dirs(config.resources_dirs, res_path)
        if reserved_app_bundle_files.include?(res)
          App.fail "Cannot use `#{res_path}' as a resource file because it's a reserved application bundle file"
        end
        dest_path = File.join(app_resources_dir, res)
        copy_resource(res_path, dest_path)
      end

      # Compile all .strings files
      config.resources_dirs.each do |dir|
        if File.exist?(dir)
          Dir.glob(File.join(dir, '{,**/}*.strings')).each do |strings_path|
            res_path = strings_path
            dest_path = File.join(app_resources_dir, path_on_resources_dirs(config.resources_dirs, res_path))

            if !File.exist?(dest_path) or File.mtime(res_path) > File.mtime(dest_path)
              unless File.size(res_path) == 0
                App.info 'Compile', dest_path
                FileUtils.mkdir_p(File.dirname(dest_path))
                sh "/usr/bin/plutil -convert binary1 \"#{res_path}\" -o \"#{dest_path}\""
              end
            end

            preserve_resources << path_on_resources_dirs(config.resources_dirs, res_path)
          end
        end
      end

      # Optional support for #eval (OSX-only).
      if config.respond_to?(:eval_support) and config.eval_support
        repl_dylib_path = File.join(datadir, '..', 'librubymotion-repl.dylib')
        dest_path = File.join(app_resources_dir, File.basename(repl_dylib_path))
        copy_resource(repl_dylib_path, dest_path)
        preserve_resources << File.basename(repl_dylib_path)
      end

      # Delete old resource files.
      resources_files = resources_paths.map { |x| path_on_resources_dirs(config.resources_dirs, x) }
      Dir.chdir(app_resources_dir) do
        Dir.glob('*').each do |bundle_res|
          next if File.directory?(bundle_res)
          next if reserved_app_bundle_files.include?(bundle_res)
          next if resources_files.include?(bundle_res)
          next if preserve_resources.include?(File.basename(bundle_res))
          App.warn "File `#{bundle_res}' found in app bundle but not in resource directories, removing"
          FileUtils.rm_rf(bundle_res)
        end
      end

      # Generate dSYM.
      if any_obj_file_built
        dsym_path = config.app_bundle_dsym(platform)
        FileUtils.rm_rf(dsym_path)
        App.info "Create", dsym_path
        sh "/usr/bin/dsymutil \"#{main_exec}\" -o \"#{dsym_path}\""

        # TODO only in debug mode
        dest_path = File.join(app_resources_dir, File.basename(dsym_path))
        FileUtils.rm_rf(dest_path)
        copy_resource(dsym_path, dest_path) if config.embed_dsym
      end

      # Strip all symbols. Only in distribution mode.
      if main_exec_created and (config.distribution_mode or ENV['__strip__'])
        App.info "Strip", main_exec
        silent_execute_and_capture "#{config.locate_binary('strip')} #{config.strip_args} '#{main_exec}'"
      end
    end

    def path_on_resources_dirs(dirs, path)
      dir = File.dirname(path)
      if dirs.include?(dir)
        path = path.sub(/^#{dir}\/*/, '')
      end
      path
    end

    def convert_filesystem_encoding(string)
      if RUBY_VERSION < "2.1.0"
        return eval `#{@nfd} "#{string}"`
      else
        # Dir.glob on Ruby 2.1 returns file path as "Normalization Form C".
        # So, we do not convert to "Normalization Form D".
        # (Ruby 2.0 or below, Dir.glob returns "Normalization Form D").
        return string
      end
    end

    def copy_resource(res_path, dest_path)
      if !File.exist?(dest_path) or File.mtime(res_path) > File.mtime(dest_path)
        FileUtils.mkdir_p(File.dirname(dest_path))
        App.info 'Copy', res_path
        FileUtils.rm_rf(dest_path)
        FileUtils.cp_r(res_path, dest_path)
      end
    end

    def profile(config, platform, config_plist)
      plist_path = File.join(config.versionized_build_dir(platform), 'pbxperfconfig.plist')
      App.info('Create', plist_path)
      plist_path = File.expand_path(plist_path)
      File.open(plist_path, 'w') { |f| f << Motion::PropertyList.to_s(config_plist) }

      instruments_app = File.expand_path('../Applications/Instruments.app', config.xcode_dir)
      App.info('Profile', config.app_bundle(platform))
      sh "'#{File.join(config.bindir, 'instruments')}' '#{instruments_app}' '#{plist_path}'"
    end

    def generate_info_plist(config, platform)
      bundle_info_plist = File.join(config.app_bundle(platform), 'Info.plist')
      if !File.exist?(bundle_info_plist) or File.mtime(config.project_file) > File.mtime(bundle_info_plist)
        App.info 'Create', bundle_info_plist
        File.open(bundle_info_plist, 'w') { |io| io.write(config.info_plist_data(platform)) }
        sh "/usr/bin/plutil -convert binary1 \"#{bundle_info_plist}\""
      end
    end

    def silent_execute_and_capture(command)
      $stderr.puts(command) if App::VERBOSE
      output = `#{command} 2>&1`
      $stderr.puts(output) if App::VERBOSE
      raise "Failed to execute: #{command}" unless $?.success?
      output
    end

    # @return [Array] A list of produced resources which should be preserved.
    #
    def compile_asset_bundles(config, platform)
      assets_bundles = config.assets_bundles
      if assets_bundles.empty?
        []
      else
        app_icon_and_launch_image_options = ''
        if config.respond_to?(:app_icons_asset_bundle) && bundle_name = config.app_icon_name_from_asset_bundle
          app_icon_and_launch_image_options << " --app-icon '#{bundle_name}'"
        end
        if config.respond_to?(:launch_images_asset_bundle) && bundle_name = config.launch_image_name_from_asset_bundle
          app_icon_and_launch_image_options << " --launch-image '#{bundle_name}'"
        end
        unless app_icon_and_launch_image_options.empty?
          partial_info_plist = config.asset_bundle_partial_info_plist_path(platform)
          app_icon_and_launch_image_options << " --output-partial-info-plist '#{partial_info_plist}'"
        end
        if platform.start_with?("AppleTV")
          app_icon_and_launch_image_options << " --app-icon 'App Icon & Top Shelf Image'"
        end

        App.info 'Compile', assets_bundles.join(", ")
        app_resources_dir = File.expand_path(config.app_resources_dir(platform))
        FileUtils.mkdir_p(app_resources_dir)
        cmd = "\"#{config.xcode_dir}/usr/bin/actool\" --output-format human-readable-text " \
              "--notices --warnings --platform #{config.deploy_platform.downcase} " \
              "--minimum-deployment-target #{config.deployment_target} " \
              "#{Array(config.device_family).map { |d| "--target-device #{d}" }.join(' ')} " \
              "#{app_icon_and_launch_image_options} --compress-pngs " \
              "--compile \"#{app_resources_dir}\" " \
              "\"#{assets_bundles.map { |f| File.expand_path(f) }.join('" "')}\""
        actool_output = silent_execute_and_capture(cmd)

        # Split output in warnings and compiled files
        actool_output, actool_compilation_results = actool_output.split('/* com.apple.actool.compilation-results */')
        actool_compiled_files = actool_compilation_results.strip.split("\n")
        if actool_document_warnings = actool_output.split('/* com.apple.actool.document.warnings */').last
          # Propagate warnings to the user.
          actool_document_warnings.strip.split("\n").each { |w| App.warn(w) }
        end

        unless app_icon_and_launch_image_options.empty?
          config.add_images_from_asset_bundles(platform)
          actool_compiled_files.delete(partial_info_plist)
        end
        produced_resources = actool_compiled_files.map { |f| File.basename(f) }
      end
    end

    class << self
      def common_build_dir
        dir = File.expand_path("~/Library/RubyMotion/build")
        unless File.exist?(dir)
          begin
            FileUtils.mkdir_p dir
          rescue
          end
        end

        # Validate common build directory.
        if !File.directory?(dir) or !File.writable?(dir)
          $stderr.puts "Cannot write into the `#{dir}' directory, please remove or check permissions and try again."
          exit 1
        end

        dir
      end
    end
  end
end; end
