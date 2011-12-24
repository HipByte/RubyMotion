module Motion; module Project;
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
      bs_files = []
      config.frameworks.each do |framework|
        bs_path = File.join(datadir, 'BridgeSupport', framework + '.bridgesupport')
        if File.exist?(bs_path)
          bs_files << bs_path
        end
      end

      # Build vendor libraries.
      vendor_libs = []
      config.vendor_projects.each do |vendor_project|
        vendor_project.build(platform, archs)
        vendor_libs.concat(vendor_project.libs)
        bs_files.concat(vendor_project.bs_files)
      end 

      # Build object files.
      objs_build_dir = File.join(build_dir, config.sdk_version + '-sdk-objs')
      FileUtils.mkdir_p(objs_build_dir)
      project_file_changed = File.mtime(config.project_file) > File.mtime(objs_build_dir)
      build_file = Proc.new do |path|
        obj ||= File.join(objs_build_dir, "#{path}.o")
        should_rebuild = (project_file_changed \
            or !File.exist?(obj) \
            or File.mtime(path) > File.mtime(obj) \
            or File.mtime(ruby) > File.mtime(obj))
 
        # Generate or retrieve init function.
        init_func = should_rebuild ? "MREP_#{`/usr/bin/uuidgen`.strip.gsub('-', '')}" : `/usr/bin/nm #{obj}`.scan(/T\s+_(MREP_.*)/)[0][0]

        if should_rebuild
          FileUtils.mkdir_p(File.dirname(obj))
          arch_objs = []
          archs.each do |arch|
            # Locate arch kernel.
            kernel = File.join(datadir, platform, "kernel-#{arch}.bc")
            raise "Can't locate kernel file" unless File.exist?(kernel)
   
            # LLVM bitcode.
            bc = File.join(objs_build_dir, "#{path}.#{arch}.bc")
            bs_flags = bs_files.map { |x| "--uses-bs \"" + x + "\" " }.join(' ')
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

        [obj, init_func]
      end
      objs = app_objs = config.ordered_build_files.map { |path| build_file.call(path) }
      if config.spec_mode
        # Build spec files too.
        objs << build_file.call(File.expand_path(File.join(File.dirname(__FILE__), '../spec.rb')))
        spec_objs = config.spec_files.map { |path| build_file.call(path) }
        objs += spec_objs
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
EOS

      if config.spec_mode
        main_txt << <<EOS
@interface SpecLauncher : NSObject
@end

@implementation SpecLauncher

+ (id)launcher
{
    SpecLauncher *launcher = [[self alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:launcher selector:@selector(appLaunched:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    return launcher; 
}

- (void)appLaunched:(id)notification
{
    [self performSelector:@selector(runSpecs) withObject:nil afterDelay:0.1];
}

- (void)runSpecs
{
EOS
        spec_objs.each do |_, init_func|
          main_txt << "#{init_func}(self, 0);\n"
        end
        main_txt << "[NSClassFromString(@\"Bacon\") performSelector:@selector(run)];\n"
        main_txt << <<EOS
}

@end
EOS
      end
      main_txt << <<EOS
int
main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    const char *progname = argv[0];
    ruby_init();
    ruby_init_loadpath();
    ruby_script(progname);
    int retval = 0;
    try {
        void *self = rb_vm_top_self();
EOS
      app_objs.each do |_, init_func|
        main_txt << "#{init_func}(self, 0);\n"
      end
      main_txt << "[SpecLauncher launcher];\n" if config.spec_mode
      main_txt << <<EOS
        retval = UIApplicationMain(argc, argv, nil, @"#{config.delegate_class}");
        rb_exit(retval);
    }
    catch (...) {
	rb_vm_print_current_exception();
        retval = 1;
    }
    [pool release];
    return retval;
}
EOS
 
      # Compile main file.
      arch_flags = archs.map { |x| "-arch #{x}" }.join(' ')
      main = File.join(objs_build_dir, 'main.mm')
      main_o = File.join(objs_build_dir, 'main.o')
      if !(File.exist?(main) and File.exist?(main_o) and File.read(main) == main_txt)
        File.open(main, 'w') { |io| io.write(main_txt) }
        sh "#{cxx} \"#{main}\" #{arch_flags} -fexceptions -fblocks -isysroot \"#{sdk}\" -miphoneos-version-min=#{config.sdk_version} -fobjc-legacy-dispatch -fobjc-abi-version=2 -c -o \"#{main_o}\""
      end

      # Prepare bundle.
      bundle_path = config.app_bundle(platform)
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
      sh "#{cxx} -o \"#{main_exec}\" #{objs_list} #{arch_flags} #{framework_stubs_objs.join(' ')} -isysroot \"#{sdk}\" -miphoneos-version-min=#{config.sdk_version} -L#{File.join(datadir, platform)} -lmacruby-static -lobjc -licucore #{frameworks} #{config.libs.join(' ')} #{vendor_libs.map { |x| '-force_load ' + x }.join(' ')}"

      # Create bundle/Info.plist.
      bundle_info_plist = File.join(bundle_path, 'Info.plist')
      File.open(bundle_info_plist, 'w') { |io| io.write(config.info_plist_data) }
      sh "/usr/bin/plutil -convert binary1 \"#{bundle_info_plist}\""

      # Create bundle/PkgInfo.
      File.open(File.join(bundle_path, 'PkgInfo'), 'w') { |io| io.write(config.pkginfo_data) }

      # Copy resources, handle subdirectories.
      reserved_app_bundle_files = [
        '_CodeSignature/CodeResources', 'CodeResources', 'embedded.mobileprovision',
        'Info.plist', 'PkgInfo', 'ResourceRules.plist',
        config.name
      ]
      resources_files = []
      if File.exist?(config.resources_dir)
        resources_files = Dir.chdir(config.resources_dir) do
          Dir.glob('**/*').reject { |x| File.directory?(x) }
        end
        resources_files.each do |res|
          res_path = File.join(config.resources_dir, res)
          if reserved_app_bundle_files.include?(res)
            $stderr.puts "Cannot use `#{res_path}' as a resource file because it's a reserved application bundle file"
            exit 1
          end
          dest_path = File.join(bundle_path, res)
          if !File.exist?(dest_path) or File.mtime(res_path) > File.mtime(dest_path)
            FileUtils.mkdir_p(File.dirname(dest_path))
p "copy #{res_path} #{dest_path}"
            FileUtils.cp(res_path, File.dirname(dest_path))
          end
        end
      end

      # Delete old resource files.
      Dir.chdir(bundle_path) do
        Dir.glob('**/*').each do |bundle_res|
          next if File.directory?(bundle_res)
          next if reserved_app_bundle_files.include?(bundle_res)
          next if resources_files.include?(bundle_res)
          $stderr.puts "File `#{bundle_res}' found in app bundle but not in `#{config.resources_dir}', removing..."
          FileUtils.rm_rf(bundle_res)
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

      # Create the entitlements file.
      entitlements = File.join(config.build_dir, platform, "Entitlements.plist")
      File.open(entitlements, 'w') { |io| io.write(config.entitlements_data) }
 
      # Do the codesigning.
      codesign_allocate = File.join(config.platform_dir(platform), 'Developer/usr/bin/codesign_allocate')
      sh "CODESIGN_ALLOCATE=\"#{codesign_allocate}\" /usr/bin/codesign -f -s \"#{config.codesign_certificate}\" --resource-rules=\"#{resource_rules_plist}\" --entitlements #{entitlements} \"#{bundle_path}\""
    end
  end
end; end
