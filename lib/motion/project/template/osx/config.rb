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

require 'motion/project/xcode_config'
require 'motion/util/version'

module Motion; module Project;
  class OSXConfig < XcodeConfig
    register :osx

    variable :icon, :copyright, :category,
        :embedded_frameworks, :external_frameworks,
        :codesign_for_development, :codesign_for_release,
        :eval_support

    def initialize(project_dir, build_mode)
      super
      @icon = ''
      @copyright = "Copyright © #{Time.now.year} #{`whoami`.strip}. All rights reserved."
      @category = 'utilities'
      @frameworks = ['AppKit', 'Foundation', 'CoreGraphics', 'CoreServices']
      @embedded_frameworks = []
      @external_frameworks = []
      @codesign_for_development = false
      @codesign_for_release = true
      @eval_support = false
    end

    def platforms; ['MacOSX']; end
    def local_platform; 'MacOSX'; end
    def deploy_platform; 'MacOSX'; end
    def device_family; 'mac'; end

    def validate
      %w{ embedded_frameworks external_frameworks }.each do |attr|
        value = send(attr)
        if !(value.is_a?(Array) and value.all? { |x| File.exist?(x) and File.extname(x) == '.framework' })
          App.fail "app.#{attr} should be an array of framework paths"
        end
      end

      super
    end

    def archs
      archs = super
      if development?
        # We only build for the native architecture in development mode, to speed up builds.
        native_arch = `/usr/bin/uname -m`.strip
        if archs['MacOSX'].include?(native_arch)
          archs['MacOSX'] = [native_arch]
        end
      end
      archs
    end

    def app_icons_info_plist_path(platform)
      '/dev/null'
    end

    # On OS X only one file is ever created. E.g. NAME.icns
    def configure_app_icons_from_asset_bundle(platform)
      self.icon = app_icon_name_from_asset_bundle
    end

    def locate_compiler(platform, *execs)
      execs.each do |exec|
        cc = File.join('/usr/bin', exec)
        return escape_path(cc) if File.exist?(cc)
      end
      App.fail "Can't locate compilers for platform `#{platform}'"
    end

    def archive_extension
      '.pkg'
    end

    def codesign_certificate
      super('Mac')
    end

    def needs_repl_sandbox_entitlements?
      development? && codesign_for_development && entitlements['com.apple.security.app-sandbox']
    end

    def entitlements_data
      dict = entitlements.dup
      if needs_repl_sandbox_entitlements?
        files = (dict['com.apple.security.temporary-exception.files.absolute-path.read-only'] ||= [])
        files << datadir('librubymotion-repl.dylib')
      end
      Motion::PropertyList.to_s(dict)
    end

    def common_flags(platform)
      super + " -mmacosx-version-min=#{deployment_target}"
    end

    def bridgesupport_flags
      "--format complete --64-bit"
    end

    def bridgesupport_cflags
      a = sdk_version.scan(/(\d+)\.(\d+)/)[0]
      sdk_version_headers = ((a[0].to_i * 10000) + (a[1].to_i * 100)).to_s
      "-mmacosx-version-min=#{sdk_version} -D__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__=#{sdk_version_headers}"
    end

    def app_bundle_raw(platform)
      File.join(versionized_build_dir(platform), bundle_name + '.app')
    end

    def app_bundle(platform)
      File.join(app_bundle_raw(platform), 'Contents')
    end

    def app_bundle_executable(platform)
      File.join(app_bundle(platform), 'MacOS', name)
    end

    def app_resources_dir(platform)
      File.join(app_bundle(platform), 'Resources')
    end

    def app_sandbox_repl_socket_path
      File.expand_path(File.join('~/Library/Containers', identifier, "Data/rubymotion-repl-#{Time.now.to_i}"))
    end

    def info_plist_data(platform)
      Motion::PropertyList.to_s({
        'NSHumanReadableCopyright' => copyright,
        'NSPrincipalClass' => 'NSApplication',
        'CFBundleIconFile' => (icon or ''),
        'LSMinimumSystemVersion' => deployment_target,
        'LSApplicationCategoryType' => (@category.start_with?('public.app-category') ? @category : 'public.app-category.' + @category)
      }.merge(generic_info_plist).merge(dt_info_plist).merge(info_plist))
    end

    def strip_args
      ''
    end

    def deployment_target
      @deployment_target ||= osx_version
    end

    def supported_sdk_versions(versions)
      versions.reverse.find { |vers|
        Util::Version.new(osx_version) <= Util::Version.new(vers) && File.exist?(datadir(vers))
      }
    end
    
    def osx_version
      `sw_vers -productVersion`.strip.match(/((\d+).(\d+))/)[0]
    end

    def main_cpp_file_txt(spec_objs)
      main_txt = <<EOS
#import <AppKit/AppKit.h>

extern "C" {
    void rb_define_global_const(const char *, void *);
    void rb_rb2oc_exc_handler(void);
    void rb_exit(int);
    void RubyMotionInit(int argc, char **argv);
EOS
      if spec_mode
        spec_objs.each do |_, init_func|
          main_txt << "void #{init_func}(void *, void *);\n"
        end
      end
      main_txt << <<EOS
}
EOS
      if spec_mode
        main_txt << <<EOS
@interface SpecLauncher : NSObject
@end

@implementation SpecLauncher

- (void)runSpecs
{
EOS
        spec_objs.each do |_, init_func|
          main_txt << "#{init_func}(self, 0);\n"
        end
        main_txt << <<EOS
        [NSClassFromString(@\"Bacon\") performSelector:@selector(run)];
}

- (void)appLaunched:(NSNotification *)notification
{
    [self runSpecs];
}

@end
EOS
      end

      main_txt << <<EOS
int
main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
EOS
    if ENV['ARR_CYCLES_DISABLE']
      main_txt << <<EOS
    setenv("ARR_CYCLES_DISABLE", "1", true);
EOS
    end
    main_txt << <<EOS
    RubyMotionInit(argc, argv);
    NSApplication *app = [NSApplication sharedApplication];
    [app setDelegate:[NSClassFromString(@"#{delegate_class}") new]];
EOS
    if spec_mode
      main_txt << "SpecLauncher *specLauncher = [[SpecLauncher alloc] init];\n"
      main_txt << "[[NSNotificationCenter defaultCenter] addObserver:specLauncher selector:@selector(appLaunched:) name:NSApplicationDidFinishLaunchingNotification object:nil];\n"
    end
    main_txt << <<EOS
    NSApplicationMain(argc, (const char **)argv);
    [pool release];
    rb_exit(0);
    return 0;
}
EOS
    end
  end
end; end
