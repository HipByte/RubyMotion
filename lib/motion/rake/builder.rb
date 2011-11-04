module Motion
  class Builder
    include Rake::DSL if Rake.const_defined?(:DSL)

    def build(config, platform)
      datadir = config.datadir
      libstatic = File.join(datadir, 'libmacruby-static.a')
      archs = Dir.glob(File.join(datadir, platform, '*.bc')).map do |path|
        path.scan(/kernel-(.+).bc$/)[0][0]
      end
      ruby = File.join(config.bindir, 'ruby')
      llc = File.join(config.bindir, 'llc')

      # Locate SDK.
      sdk = config.sdk(platform)

      # Locate compilers.
      cc = File.join(config.platform_dir(platform), 'Developer/usr/bin/gcc')
      cxx = File.join(config.platform_dir(platform), 'Developer/usr/bin/g++')
    
      build_dir = File.join(config.build_dir, platform)
  
      # Prepare the list of BridgeSupport files needed. 
      bs_flags = ''
      config.frameworks.each do |framework|
        bs_path = File.join(datadir, 'BridgeSupport', framework + '.bridgesupport')
        if File.exist?(bs_path)
          bs_flags << "--uses-bs \"" + bs_path + "\" "
        end
      end

      objs = []
      objs_build_dir = File.join(build_dir, 'objs')
      FileUtils.mkdir_p(objs_build_dir)
      project_file_changed = File.mtime(config.project_file) > File.mtime(objs_build_dir)
      config.ordered_build_files.each do |path|
        obj = File.join(objs_build_dir, "#{path}.o")
        should_rebuild = (project_file_changed \
            or !File.exist?(obj) \
            or File.mtime(path) > File.mtime(obj) \
            or File.mtime(ruby) > File.mtime(obj))
 
        # Generate or retrieve init function.
        init_func = should_rebuild ? "MREP_#{`uuidgen`.strip.gsub('-', '')}" : `nm #{obj}`.scan(/T\s+_(MREP_.*)/)[0][0]
        objs << [obj, init_func]

        next unless should_rebuild   
 
        arch_objs = []
        archs.each do |arch|
          # Locate arch kernel.
          kernel = File.join(datadir, platform, "kernel-#{arch}.bc")
          raise "Can't locate kernel file" unless File.exist?(kernel)
 
          # Prepare build_dir. 
          bc = File.join(objs_build_dir, "#{path}.#{arch}.bc")
          FileUtils.mkdir_p(File.dirname(bc))

          # LLVM bitcode.
          sh "/usr/bin/env VM_KERNEL_PATH=\"#{kernel}\" #{ruby} #{bs_flags} --emit-llvm \"#{bc}\" #{init_func} \"#{path}\""
 
          # Assembly.
          asm = File.join(objs_build_dir, "#{path}.#{arch}.s")
          llc_arch = case arch
            when 'i386'; 'x86'
            when 'x86_64'; 'x86-64'
            when /^arm/; 'arm'
            else; arch
          end
          sh "#{llc} \"#{bc}\" -o=\"#{asm}\" -march=#{llc_arch} -relocation-model=pic -disable-fp-elim -jit-enable-eh -disable-cfi"
 
          # Object.
          arch_obj = File.join(objs_build_dir, "#{path}.#{arch}.o")
          sh "#{cc} -fexceptions -c -arch #{arch} \"#{asm}\" -o \"#{arch_obj}\""
 
          arch_objs << arch_obj
        end
 
        # Assemble fat binary.
        arch_objs_list = arch_objs.map { |x| "\"#{x}\"" }.join(' ')
        sh "lipo -create #{arch_objs_list} -output \"#{obj}\""
      end

      # Generate main file.
      main_txt = <<EOS
#import <UIKit/UIKit.h>
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
    void rb_vm_print_current_exception(void);
    void rb_exit(int);
EOS
      objs.each do |_, init_func|
        main_txt << "void #{init_func}(void *, void *);\n"
      end
      main_txt << <<EOS
}
int
main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    const char *progname = argv[0];
    ruby_init();
    ruby_init_loadpath();
    ruby_script(progname);
    try {
      void *self = rb_vm_top_self();
EOS
      objs.each do |_, init_func|
        main_txt << "#{init_func}(self, 0);\n"
      end
      main_txt << <<EOS
    }
    catch (...) {
	rb_vm_print_current_exception();
	rb_exit(1);
    }
    int retval = UIApplicationMain(argc, argv, nil, @"#{config.delegate_class}");
    [pool release];
    rb_exit(retval);
}
EOS
 
      # Compile main file.
      arch_flags = archs.map { |x| "-arch #{x}" }.join(' ')
      main = File.join(objs_build_dir, 'main.mm')
      main_o = File.join(objs_build_dir, 'main.o')
      if !(File.exist?(main) and File.exist?(main_o) and File.read(main) == main_txt)
        File.open(main, 'w') { |io| io.write(main_txt) }
        sh "#{cxx} \"#{main}\" #{arch_flags} -fexceptions -fblocks -isysroot \"#{sdk}\" -miphoneos-version-min=4.3 -fobjc-legacy-dispatch -fobjc-abi-version=2 -c -o \"#{main_o}\""
      end

      # Prepare bundle.
      bundle_path = File.join(build_dir, config.name + '.app')
      FileUtils.mkdir_p(bundle_path)

      # Link executable.
      main_exec = File.join(bundle_path, config.name)
      objs_list = objs.map { |path, _| path }.unshift(main_o).map { |x| "\"#{x}\"" }.join(' ')
      frameworks = config.frameworks.map { |x| "-framework #{x}" }.join(' ')
      framework_stubs_objs = []
      config.frameworks.each do |framework|
        stubs_obj = File.join(datadir, platform, "#{framework}_stubs.o")
        framework_stubs_objs << "\"#{stubs_obj}\"" if File.exist?(stubs_obj)
      end
      sh "#{cxx} -o \"#{main_exec}\" #{objs_list} #{arch_flags} #{framework_stubs_objs.join(' ')} -isysroot \"#{sdk}\" -L#{File.join(datadir, platform)} -lmacruby-static -lobjc -licucore #{frameworks}"

      # Create bundle/Info.plist.
      bundle_info_plist = File.join(bundle_path, 'Info.plist')
      File.open(bundle_info_plist, 'w') { |io| io.write(config.plist_data) }
      sh "/usr/bin/plutil -convert binary1 \"#{bundle_info_plist}\""

      # Create bundle/PkgInfo.
      File.open(File.join(bundle_path, 'PkgInfo'), 'w') { |io| io.write(config.pkginfo_data) }

      # Copy resources.
      Dir.glob(File.join(config.resources_dir, '*')).each do |res_path|
        next if res_path[0] == '.'
        dest_path = File.join(bundle_path, File.basename(res_path))
        if !File.exist?(dest_path) or File.mtime(res_path) > File.mtime(dest_path)
          sh "/bin/cp \"#{res_path}\" \"#{dest_path}\""
        end
      end
    end

    def codesign(config, platform)
      bundle_path = File.join(config.build_dir, platform, config.name + '.app')
      raise unless File.exist?(bundle_path)

      # Create bundle/ResourceRules.plist.
      resource_rules_plist = File.join(bundle_path, 'ResourceRules.plist')
      File.open(resource_rules_plist, 'w') do |io|
        io.write(<<-PLIST)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>rules</key>
        <dict>
                <key>.*</key>
                <true/>
                <key>Info.plist</key>
                <dict>
                        <key>omit</key>
                        <true/>
                        <key>weight</key>
                        <real>10</real>
                </dict>
                <key>ResourceRules.plist</key>
                <dict>
                        <key>omit</key>
                        <true/>
                        <key>weight</key>
                        <real>100</real>
                </dict>
        </dict>
</dict>
</plist>
PLIST
      end

      # Copy the provisioning profile.
      File.open(File.join(bundle_path, "embedded.mobileprovision"), 'w') do |io|
        io.write(File.read(config.provisioning_profile))
      end
 
      # Do the codesigning.
      codesign_allocate = File.join(config.platform_dir(platform), 'Developer/usr/bin/codesign_allocate')
      sh "CODESIGN_ALLOCATE=\"#{codesign_allocate}\" /usr/bin/codesign -f -s \"#{config.codesign_certificate}\" --resource-rules=\"#{resource_rules_plist}\" \"#{bundle_path}\""
    end
  end
end
