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
      @frameworks = [ "AppKit", "Foundation", "CoreServices", "Security",
                      "CoreGraphics", "ApplicationServices", "AudioToolbox",
                      "AudioUnit", "CoreData", "CoreAudio", "CoreFoundation",
                      "CFNetwork"]
      # In 10.7, CoreGraphics is a subframework of ApplicationServices
      @frameworks << 'CoreGraphics' if deployment_target != "10.7"
      @codesign_for_development = false
      @codesign_for_release = true
      @eval_support = false
    end

    def platforms; ['MacOSX']; end
    def local_platform; 'MacOSX'; end
    def deploy_platform; 'MacOSX'; end
    def device_family; 'mac'; end

    def validate
      sdk_ver = Util::Version.new(sdk_version)
      if sdk_ver >= Util::Version.new('10.11') && osx_host_version < sdk_ver
        App.fail "To use specified OSX SDK version, it requires running on host of same OSX version or higher. But you are running OSX #{osx_host_version}"
      end

      super
    end

    def archs
      @archs ||= begin
        archs = super
        archs['MacOSX'].delete('i386')
        archs
      end
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
      super + cflag_version_min(platform)
    end

    def cflag_version_min(platform)
      " -mmacosx-version-min=#{deployment_target}"
    end

    def bridgesupport_flags
      "--format complete --64-bit"
    end

    def bridgesupport_cflags
      a = sdk_version.scan(/(\d+)\.(\d+)/)[0]
      major = a[0].to_i
      minor = a[1].to_i
      if major <= 10 && minor <= 9
        sdk_version_headers = "#{major}#{minor}0"
      else
        sdk_version_headers = "#{major}#{minor}00"
      end
      "-mmacosx-version-min=#{sdk_version} -D__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__=#{sdk_version_headers}"
    end

    def app_bundle_raw(platform)
      File.join(versionized_build_dir(platform), bundle_filename)
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

    def generic_info_plist
      super.merge({
        'NSHumanReadableCopyright' => copyright,
        'NSPrincipalClass' => 'NSApplication',
        'CFBundleIconFile' => (icon or ''),
        'LSMinimumSystemVersion' => deployment_target,
        'LSApplicationCategoryType' => (@category.start_with?('public.app-category') ? @category : 'public.app-category.' + @category)
      })
    end

    def strip_args
      ' -x'
    end

    # Defaults to the MAJOR and MINOR version of the host machine. For example,
    # on Yosemite this defaults to `10.10`.
    #
    # @return [String] the lowest OS version that this target will support.
    #
    def deployment_target
      @deployment_target ||= osx_host_version.segments.first(2).join('.')
    end

    def sdk(platform)
      # FIXME
      # Now, Xcode 7 beta doesn't have binaries of each frameworks, and we need them
      # to solve framework dependencies.
      if osx_host_version >= Util::Version.new('10.11')
        '/'
      else
        super(platform)
      end
    end

    def supported_sdk_versions(versions)
      versions.reverse.find { |vers|
        Util::Version.new(deployment_target) <= Util::Version.new(vers) && File.exist?(datadir(vers))
      }
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
        [NSClassFromString(@\"Bacon\") performSelector:@selector(run) withObject:nil];
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
    main_txt << "    setenv(\"VM_OPT_LEVEL\", \"#{App.config.opt_level}\", true);\n"
    if ENV['ARR_CYCLES_DISABLE']
      main_txt << <<EOS
    setenv("ARR_CYCLES_DISABLE", "1", true);
EOS
    end
    main_txt << <<EOS
    RubyMotionInit(argc, argv);
    NSApplication *app = [NSClassFromString(@"#{merged_info_plist('MacOSX')['NSPrincipalClass']}") sharedApplication];
    [app setDelegate:[NSClassFromString(@"#{delegate_class}") new]];
EOS
    if spec_mode
      main_txt << "    SpecLauncher *specLauncher = [[SpecLauncher alloc] init];\n"
      main_txt << "    [[NSNotificationCenter defaultCenter] addObserver:specLauncher selector:@selector(appLaunched:) name:NSApplicationDidFinishLaunchingNotification object:nil];\n"
    end
    if use_application_main_function?
      main_txt << "    NSApplicationMain(argc, (const char **)argv);\n"
    else
      main_txt << "    [app run];\n"
    end
    main_txt << <<EOS
    [pool release];
    rb_exit(0);
    return 0;
}
EOS
    end

    # If the user specifies a custom principal class the NSApplicationMain()
    # function will only work if they have also specified a nib or storyboard.
    def use_application_main_function?
      info = merged_info_plist('MacOSX')
      if info['NSPrincipalClass'] == 'NSApplication'
        true
      else
        files = info.values_at('NSMainNibFile', 'NSMainStoryboardFile').compact
        files.any? { |file| !file.strip.empty? }
      end
    end
  end
end; end
