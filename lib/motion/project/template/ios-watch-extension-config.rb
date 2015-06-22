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

module Motion; module Project;
  class IOSWatchExtensionConfig < IOSExtensionConfig
    register :'ios-extension'

    def initialize(*)
      super
      @name = nil
      @version = ENV['RM_TARGET_HOST_APP_VERSION']
      @short_version = ENV['RM_TARGET_HOST_APP_SHORT_VERSION']
      @frameworks = ['WatchKit', 'Foundation', 'CoreGraphics']
      @deployment_target = '8.2' # FIXME: Now, iTunnes require '8.2' as MinimumOSVersion
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

    # @return [String] The bundle identifier of the watch extension based on the
    #         bundle identifier of the host application.
    #
    def identifier
      ENV['RM_TARGET_HOST_APP_IDENTIFIER'] + '.watchkitextension'
    end

    # @see {XcodeConfig#merged_info_plist}
    #
    def merged_info_plist(platform)
      super.merge({
        'UIRequiredDeviceCapabilities' => ['watch-companion'],
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
    void rb_exit(int);
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
    rb_exit(retval);
    [pool release];
    return retval;
}
EOS
    end

    # This config class is mostly used to re-use existing filename/path APIs as
    # they are in any other iOS application and to build an Info.plist.
    #
    # We do not actually compile this application, it's only assembled from an
    # existing `SP.app` application template inside the SDK.
    #
    class WatchAppConfig < IOSConfig
      def initialize(project_dir, build_mode, extension_config)
        super(project_dir, build_mode)
        @name = nil
        @files = []
        @resources_dirs = ['watch_app']
        @specs_dir = nil
        @detect_dependencies = false

        @delegate_class = "SPApplicationDelegate"
        @extension_config = extension_config

        @name = ENV['RM_TARGET_HOST_APP_NAME'] + ' WatchKit App'
        @version = ENV['RM_TARGET_HOST_APP_VERSION']
        @short_version = ENV['RM_TARGET_HOST_APP_SHORT_VERSION']
      end

      def sdk_version
        @extension_config.sdk_version
      end

      def deployment_target
        @extension_config.deployment_target
      end

      # Ensure that we also compile assets with `actool` for the watch.
      #
      def device_family
        [:iphone, :watch]
      end

      # @return [String] The bundle identifier of the watch application based on
      #         the bundle identifier of the host application.
      #
      def identifier
        ENV['RM_TARGET_HOST_APP_IDENTIFIER'] + '.watchkitapp'
      end

      # @todo There are more differences with Xcode's Info.plist.
      #
      # @see {XcodeConfig#merged_info_plist}
      #
      def merged_info_plist(platform)
        plist = super
        plist['CFBundleDisplayName'] = ENV['RM_TARGET_HOST_APP_NAME']
        plist['UIDeviceFamily'] << 4 # Probably means Apple Watch device?
        plist['WKWatchKitApp'] = true
        plist['WKCompanionAppBundleIdentifier'] = ENV['RM_TARGET_HOST_APP_IDENTIFIER']
        plist.delete('UIBackgroundModes')
        plist.delete('UIStatusBarStyle')
        plist.delete('CFBundleResourceSpecification')
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
        File.join(@extension_config.app_bundle(platform), bundle_filename)
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
        @extension_config.bundle_name.gsub(" ", "_")
      end
    end
  end
end; end
