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

require 'motion/project/template/ios-extension-config'
require 'motion/project/template/ios/config'

module Motion; module Project
  class IOSWatchExtensionConfig < IOSExtensionConfig
    register :'ios-extension'

    def initialize(*)
      super
      @name = nil
      @version = ENV['RM_TARGET_HOST_APP_VERSION']
      @short_version = ENV['RM_TARGET_HOST_APP_SHORT_VERSION']
      @frameworks = ['WatchKit', 'UIKit', 'Foundation', 'CoreGraphics',
                     'CoreFoundation', 'MapKit']
      ENV.delete('RM_TARGET_DEPLOYMENT_TARGET')
    end

    # @return [String] The name of the Watch extension is always based on that
    #         of the host application.
    #
    def name
      @name = ENV['RM_TARGET_HOST_APP_NAME'] + ' WatchKit Extension'
    end

    def name=(name)
      App.fail 'You cannot give a Watch application a custom name, it will ' \
               'automatically be named after the host application.'
    end

    # TODO datadir should not depend on the template name
    def datadir(target=deployment_target)
      File.join(motiondir, 'data', 'watchos', target)
    end

    # TODO datadir should not depend on the template name
    def supported_versions
      @supported_versions ||= Dir.glob(File.join(motiondir, 'data', 'watchos', '*')).select{ |path| File.directory?(path) }.map do |path|
        File.basename path
      end
    end

    def platforms
      %w(WatchSimulator WatchOS)
    end

    def local_platform
      'WatchSimulator'
    end

    def deploy_platform
      'WatchOS'
    end

    # @return [String] The bundle identifier of the watch extension based on the
    #         bundle identifier of the host application.
    #
    def identifier
      ENV['RM_TARGET_HOST_APP_IDENTIFIER'] + '.watchkitapp.watchkitextension'
    end

    # @see {XcodeConfig#merged_info_plist}
    #
    def merged_info_plist(platform)
      plist = super
      plist.delete('UIAppFonts')
      plist.delete('CFBundleIcons')
      plist.delete('CFBundleIconFiles')
      plist.delete('LSApplicationCategoryType')
      plist.delete('UISupportedInterfaceOrientations')
      plist['WKExtensionDelegateClassName'] = 'ExtensionDelegate'
      plist['MinimumOSVersion'] = deployment_target
      plist['UIDeviceFamily'] = [4]
      plist['CFBundleSupportedPlatforms'] = ['WatchOS']
      plist.merge({
        'RemoteInterfacePrincipalClass' => 'InterfaceController',
        'NSExtension' => {
          'NSExtensionPointIdentifier' => 'com.apple.watchkit',
          'NSExtensionAttributes' => {
            'WKAppBundleIdentifier' => watch_app_config.identifier,
          },
        },
      })
    end

    # @return [WatchAppConfig] A config instance for the watch application.
    #
    def watch_app_config
      @watch_app_config ||= WatchAppConfig.new(@project_dir, @build_mode, self)
    end

    def main_cpp_file_txt(spec_objs)
      main_txt = <<EOS
#import <UIKit/UIKit.h>
#include <objc/message.h>
#include <dlfcn.h>

extern "C" {
    void rb_define_global_const(const char *, void *);
    void rb_rb2oc_exc_handler(void);
    void RubyMotionInit(int argc, char **argv);
EOS
      main_txt << <<EOS
}
EOS
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
    main_txt << <<EOS
    RubyMotionInit(argc, argv);
EOS
    main_txt << <<EOS
    void *WatchKit = dlopen("/System/Library/Frameworks/WatchKit.framework/WatchKit", 0x2);
    int (*real_main)(void) = (int (*)(void))dlsym(WatchKit, "main");
    retval = real_main();
    exit(retval);
    [pool release];
    return retval;
}
EOS
    end

    def app_bundle(platform)
      File.join(watch_app_config.app_bundle(platform), 'PlugIns', bundle_name + '.appex')
    end

    def cflags(platform, cplusplus)
      cflags = super
      if platform == 'WatchOS'
        cflags += ' -fembed-bitcode'
      end
      cflags
    end

    def ldflags(platform)
      ldflags = super
      if platform == 'WatchOS'
        ldflags += ' -fembed-bitcode -Xlinker -bitcode_hide_symbols'
        ldflags.gsub!(' -Wl,-no_pie', '')
      end
      ldflags
    end

    # This config class is mostly used to re-use existing filename/path APIs as
    # they are in any other iOS application and to build an Info.plist.
    #
    # We do not actually compile this application, it's only assembled from an
    # existing `SP.app` application template inside the SDK.
    #
    class WatchAppConfig < IOSConfig
      attr_accessor :extension_config

      def initialize(project_dir, build_mode, extension_config)
        super(project_dir, build_mode)
        @name = nil
        @files = []
        @resources_dirs = ['watch_app']
        @specs_dir = nil
        @detect_dependencies = false

        @delegate_class = "SPApplicationDelegate"
        @extension_config = extension_config

        if ENV['RM_TARGET_HOST_APP_NAME']
          @name = ENV['RM_TARGET_HOST_APP_NAME'] + ' WatchKit App'
        end
        @version = ENV['RM_TARGET_HOST_APP_VERSION']
        @short_version = ENV['RM_TARGET_HOST_APP_SHORT_VERSION']
      end

      def sdk_version
        @extension_config.sdk_version
      end

      def deployment_target
        @extension_config.deployment_target
      end

      def deploy_platform
        'WatchOS'
      end

      # Ensure that we also compile assets with `actool` for the watch.
      #
      def device_family
        :watch
      end

      # @return [String] The bundle identifier of the watch application based on
      #         the bundle identifier of the host application.
      #
      def identifier
        ENV['RM_TARGET_HOST_APP_IDENTIFIER'] + '.watchkitapp'
      end

      def entitlements_data
        dict = entitlements
        dict['application-identifier'] ||= seed_id + '.' + identifier
        Motion::PropertyList.to_s(dict)
      end

      # @todo There are more differences with Xcode's Info.plist.
      #
      # @see {XcodeConfig#merged_info_plist}
      #
      def merged_info_plist(platform)
        plist = super
        plist['CFBundleDisplayName'] = ENV['RM_TARGET_HOST_APP_NAME']
        plist['WKWatchKitApp'] = true
        plist['WKCompanionAppBundleIdentifier'] = ENV['RM_TARGET_HOST_APP_IDENTIFIER']
        plist['UIDeviceFamily'] = [4]
        plist['MinimumOSVersion'] = deployment_target
        plist['CFBundleSupportedPlatforms'] = ['WatchOS']
        plist['UISupportedInterfaceOrientations'] = ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown']
        plist.delete('UIAppFonts')
        plist.delete('LSApplicationCategoryType')
        plist.delete('UIBackgroundModes')
        plist.delete('UIStatusBarStyle')
        plist
      end

      # @param [String] platform
      #        The platform identifier that's being build for, such as
      #        `iPhoneSimulator` or `iPhoneOS`.
      #
      # @return [String] The path to the application bundle in this extension's
      #         build directory.
      #
      def app_bundle(platform)
        File.join(versionized_build_dir(platform), bundle_name + '.app')
      end

      # @return [String] The path to the SockPuppet application executable that
      #         we copy and use as-is.
      #
      def prebuilt_app_executable(platform)
        File.join(sdk(platform), "/Library/Application Support/WatchKit/WK")
      end

      # @todo Do we really need this? `man ibtool` seems to indicate it's needed
      #       when the document references a Swift class.
      #
      # @return [String] The module name to include in applicable custom class
      #         names at runtime.
      #
      def escaped_storyboard_module_name
        ENV['RM_TARGET_HOST_APP_NAME'] + "_Extension"
      end
    end
  end
end; end
