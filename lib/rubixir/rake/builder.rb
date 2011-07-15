module Rubixir
  class Builder
    def compile(config, platform)
      datadir = File.join(File.dirname(__FILE__), '../../../data')
      libstatic = File.join(datadir, 'libmacruby-static.a')
      archs = Dir.glob(File.join(datadir, platform, '*.bc')).map do |path|
        path.scan(/kernel-(.+).bc$/)[0][0]
      end
      ruby = File.join(datadir, 'ruby')
      llc = File.join(datadir, 'llc')

      # Locate SDK.
      sdk = config.sdk(platform)

      # Locate compilers.
      cc = File.join(config.platform_dir(platform), 'Developer/usr/bin/gcc')
      cxx = File.join(config.platform_dir(platform), 'Developer/usr/bin/g++')
    
      build_dir = File.join(config.build_dir, platform)
   
      bs_flags = ''
      config.frameworks.each do |framework|
        bs_path = File.join(datadir, 'BridgeSupport', framework + '.bridgesupport')
        if File.exist?(bs_path)
          bs_flags << "--uses-bs \"" + bs_path + "\" "
        end
      end
 
      objs = []
      config.files.each do |path|
        # Generate init function.
        init_func = "MREP_#{`uuidgen`.strip.gsub('-', '')}"
    
        arch_objs = []
        archs.each do |arch|
          # Locate arch kernel.
          kernel = File.join(datadir, platform, "kernel-#{arch}.bc")
          raise "Can't locate kernel file" unless File.exist?(kernel)
    
          # Prepare build_dir. 
          bc = File.join(build_dir, "#{path}.#{arch}.bc")
          FileUtils.mkdir_p(File.dirname(bc))
    
          # LLVM bitcode.
          sh "/usr/bin/env VM_KERNEL_PATH=\"#{kernel}\" #{ruby} #{bs_flags} --emit-llvm \"#{bc}\" #{init_func} \"#{path}\""
    
          # Assembly.
          asm = File.join(build_dir, "#{path}.#{arch}.s")
          llc_arch = case arch
            when 'i386'; 'x86'
            when 'x86_64'; 'x86-64'
            when /^arm/; 'arm'
            else; arch
          end
          sh "#{llc} \"#{bc}\" -o=\"#{asm}\" -march=#{llc_arch} -relocation-model=pic -disable-fp-elim -jit-enable-eh"
    
          # Object.
          obj = File.join(build_dir, "#{path}.#{arch}.o")
          sh "#{cc} -fexceptions -c -arch #{arch} \"#{asm}\" -o \"#{obj}\""
    
          arch_objs << obj
        end
    
        # Assemble fat binary.
        arch_objs_list = arch_objs.map { |x| "\"#{x}\"" }.join(' ')
        obj = File.join(build_dir, "#{path}.o")
        sh "lipo -create #{arch_objs_list} -output \"#{obj}\""
    
        objs << [obj, init_func]
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
    int retval = UIApplicationMain(argc, argv, nil, @"AppDelegate");
    [pool release];
    rb_exit(retval);
}
EOS
    
      # Compile main file.
      main = File.join(build_dir, 'main.mm')
      File.open(main, 'w') { |io| io.write(main_txt) }
      main_o = File.join(build_dir, 'main.o')
      arch_flags = archs.map { |x| "-arch #{x}" }.join(' ')
      sh "#{cxx} \"#{main}\" #{arch_flags} -fexceptions -fblocks -isysroot \"#{sdk}\" -miphoneos-version-min=4.3 -fobjc-legacy-dispatch -fobjc-abi-version=2 -c -o \"#{main_o}\""
    
      # Link executable.
      objs_list = objs.map { |path, _| path }.unshift(main_o).map { |x| "\"#{x}\"" }.join(' ')
      main_exec = File.join(build_dir, "main")
      frameworks = config.frameworks.map { |x| "-framework #{x}" }.join(' ')
      framework_stubs_objs = []
      config.frameworks.each do |framework|
        stubs_obj = File.join(datadir, platform, "#{framework}_stubs.o")
        framework_stubs_objs << stubs_obj if File.exist?(stubs_obj)
      end
      sh "#{cxx} -o #{main_exec} #{objs_list} #{arch_flags} -isysroot \"#{sdk}\" -L#{File.join(datadir, platform)} -lmacruby-static -lobjc -licucore #{frameworks} #{framework_stubs_objs.join(' ')}" 
    end
  end
end
