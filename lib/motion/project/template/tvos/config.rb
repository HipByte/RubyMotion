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

require 'motion/project/template/ios/config'

module Motion; module Project
  class TVOSConfig < IOSConfig
    register :tvos

    def initialize(*)
      super
      @device_family = :tv
    end

    # TODO datadir should not depend on the template name
    def datadir(target=deployment_target)
      File.join(motiondir, 'data', 'tvos', target)
    end

    # TODO datadir should not depend on the template name
    def supported_versions
      @supported_versions ||= Dir.glob(File.join(motiondir, 'data', 'tvos', '*')).select{ |path| File.directory?(path) }.map do |path|
        File.basename path
      end
    end

    def platforms
      %w(AppleTVSimulator AppleTVOS)
    end

    def local_platform
      'AppleTVSimulator'
    end

    def deploy_platform
      'AppleTVOS'
    end
    def provisioning_profile(name = /tvOS\s?Team Provisioning Profile/)
      super(name)
    end

    # @see {XcodeConfig#merged_info_plist}
    #
    def merged_info_plist(platform)
      plist = super
      plist.delete('CFBundleIcons')
      plist.delete('CFBundleIconFiles')
      plist.delete('UISupportedInterfaceOrientations')

      plist['UIDeviceFamily'] = [3]
      plist['UIRequiredDeviceCapabilities'] = ['arm64']
      plist['CFBundleIcons'] = {
        'CFBundlePrimaryIcon' => "App Icon - Small"
      }
      plist['TVTopShelfImage'] = {
        'TVTopShelfPrimaryImage' => "Top Shelf Image",
        'TVTopShelfPrimaryImageWide' => "Top Shelf Image Wide"
      }
      plist['UILaunchImages'] = [
        {
          'UILaunchImageMinimumOSVersion' => "9.0",
          'UILaunchImageName' => "LaunchImage",
          'UILaunchImageOrientation' => "Landscape",
          'UILaunchImageSize' => "{1920, 1080}"
        }
      ]
      plist
    end

    def cflags(platform, cplusplus)
      cflags = super
      if platform == 'AppleTVOS'
        cflags += ' -fembed-bitcode'
      end
      cflags
    end

     def ldflags(platform)
       ldflags = super
       if platform == 'AppleTVOS'
         ldflags += ' -fembed-bitcode -Xlinker -bitcode_hide_symbols'
         ldflags.gsub!(' -Wl,-no_pie', '')
       end
       ldflags
     end

    def cflag_version_min(platform)
      flag = " -mtvos-version-min=#{deployment_target}"
      if platform == "AppleTVSimulator"
        flag = " -mtvos-simulator-version-min=#{deployment_target}"
      end
      flag
    end

    def bridgesupport_cflags
      a = sdk_version.scan(/(\d+)\.(\d+)/)[0]
      sdk_version_headers = ((a[0].to_i * 10000) + (a[1].to_i * 100)).to_s
      "-mtvos-version-min=#{sdk_version} -D__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__=#{sdk_version_headers}"
    end

    def main_cpp_file_txt(spec_objs)
      main_txt = <<EOS
#import <UIKit/UIKit.h>

extern "C" {
    void rb_define_global_const(const char *, void *);
    void rb_rb2oc_exc_handler(void);
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

#include <dlfcn.h>

@implementation SpecLauncher

+ (id)launcher
{
    [UIApplication sharedApplication];

    // Enable simulator accessibility.
    // Thanks http://www.stewgleadow.com/blog/2011/10/14/enabling-accessibility-for-ios-applications/
    NSString *simulatorRoot = [[[NSProcessInfo processInfo] environment] objectForKey:@"IPHONE_SIMULATOR_ROOT"];
    if (simulatorRoot != nil) {
        void *appSupportLibrary = dlopen([[simulatorRoot stringByAppendingPathComponent:@"/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport"] fileSystemRepresentation], RTLD_LAZY);
        CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(CFStringRef domain) = (CFStringRef (*)(CFStringRef)) dlsym(appSupportLibrary, "CPCopySharedResourcesPreferencesDomainForDomain");

        if (copySharedResourcesPreferencesDomainForDomain != NULL) {
            CFStringRef accessibilityDomain = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));

            if (accessibilityDomain != NULL) {
                CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"), kCFBooleanTrue, accessibilityDomain, kCFPreferencesAnyUser, kCFPreferencesAnyHost);
                CFRelease(accessibilityDomain);
            }
        }
    }

    // Load the UIAutomation framework.
    dlopen("/Developer/Library/PrivateFrameworks/UIAutomation.framework/UIAutomation", RTLD_LOCAL);

    SpecLauncher *launcher = [[self alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:launcher selector:@selector(appLaunched:) name:UIApplicationDidBecomeActiveNotification object:nil];
    return launcher;
}

- (void)appLaunched:(id)notification
{
    // unregister observer to avoid duplicate invocation
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    // Give a bit of time for the simulator to attach...
    [self performSelector:@selector(runSpecs) withObject:nil afterDelay:0.3];
}

- (void)runSpecs
{
EOS
        spec_objs.each do |_, init_func|
          main_txt << "#{init_func}(self, 0);\n"
        end
        main_txt << "[NSClassFromString(@\"Bacon\") performSelector:@selector(run) withObject:nil];\n"
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
    int retval = 0;
EOS
    main_txt << "    setenv(\"VM_OPT_LEVEL\", \"#{App.config.opt_level}\", true);\n"
    if ENV['ARR_CYCLES_DISABLE']
      main_txt << <<EOS
    setenv("ARR_CYCLES_DISABLE", "1", true);
EOS
    end
    main_txt << "[SpecLauncher launcher];\n" if spec_mode
    main_txt << <<EOS
    RubyMotionInit(argc, argv);
EOS
    main_txt << <<EOS
    retval = UIApplicationMain(argc, argv, nil, @"#{delegate_class}");
    exit(retval);
    [pool release];
    return retval;
}
EOS
    end

  end
end; end
