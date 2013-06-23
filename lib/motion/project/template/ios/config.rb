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

module Motion; module Project;
  class IOSConfig < XcodeConfig
    register :ios

    variable :device_family, :interface_orientations, :background_modes,
      :status_bar_style, :icons, :prerendered_icon, :fonts, :seed_id,
      :provisioning_profile, :manifest_assets

    def initialize(project_dir, build_mode)
      super
      @frameworks = ['UIKit', 'Foundation', 'CoreGraphics']
      @device_family = :iphone
      @interface_orientations = [:portrait, :landscape_left, :landscape_right]
      @background_modes = []
      @status_bar_style = :default
      @icons = []
      @prerendered_icon = false
      @manifest_assets = []
    end

    def platforms; ['iPhoneSimulator', 'iPhoneOS']; end
    def local_platform; 'iPhoneSimulator'; end
    def deploy_platform; 'iPhoneOS'; end

    def validate
      # icons
      if !(icons.is_a?(Array) and icons.all? { |x| x.is_a?(String) })
        App.fail "app.icons should be an array of strings."
      end

      # manifest_assets
      if !(manifest_assets.is_a?(Array) and manifest_assets.all? { |x| x.is_a?(Hash) and x.keys.include?(:kind) and x.keys.include?(:url) })
        App.fail "app.manifest_assets should be an array of hashes with values for the :kind and :url keys"
      end

      super
    end

    def locate_compiler(platform, *execs)
      paths = [File.join(platform_dir(platform), 'Developer/usr/bin')]
      paths.unshift File.join(xcode_dir, 'Toolchains/XcodeDefault.xctoolchain/usr/bin')

      # XXX We temporarily retrieve compilers from Xcode 4 until we completely switch to clang.
      paths << "/Applications/Xcode.app/Contents/Developer/Platforms/#{platform}.platform/Developer/usr/bin"

      execs.each do |exec|
        paths.each do |path|
          cc = File.join(path, exec)
          return escape_path(cc) if File.exist?(cc)
        end
      end
      App.fail "Can't locate compilers for platform `#{platform}'"
    end

    def archive_extension
      '.ipa'
    end

    def codesign_certificate
      super('iPhone')
    end

    def provisioning_profile(name = /iOS Team Provisioning Profile/)
      @provisioning_profile ||= begin
        paths = Dir.glob(File.expand_path("~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision")).select do |path|
          text = File.read(path)
          text.force_encoding('binary') if RUBY_VERSION >= '1.9.0'
          text.scan(/<key>\s*Name\s*<\/key>\s*<string>\s*([^<]+)\s*<\/string>/)[0][0].match(name)
        end
        if paths.size == 0
          App.fail "Can't find a provisioning profile named `#{name}'"
        elsif paths.size > 1
          App.warn "Found #{paths.size} provisioning profiles named `#{name}'. Set the `provisioning_profile' project setting. Will use the first one: `#{paths[0]}'"
        end
        paths[0]
      end
    end

    def read_provisioned_profile_array(key)
      text = File.read(provisioning_profile)
      text.force_encoding('binary') if RUBY_VERSION >= '1.9.0'
      text.scan(/<key>\s*#{key}\s*<\/key>\s*<array>(.*?)\s*<\/array>/m)[0][0].scan(/<string>(.*?)<\/string>/).map { |str| str[0].strip }
    end
    private :read_provisioned_profile_array

    def provisioned_devices
      @provisioned_devices ||= read_provisioned_profile_array('ProvisionedDevices')
    end

    def seed_id
      @seed_id ||= begin
        seed_ids = read_provisioned_profile_array('ApplicationIdentifierPrefix')
        if seed_ids.size == 0
          App.fail "Can't find an application seed ID in the provisioning profile `#{provisioning_profile}'"
        elsif seed_ids.size > 1
          App.warn "Found #{seed_ids.size} seed IDs in the provisioning profile. Set the `seed_id' project setting. Will use the last one: `#{seed_ids.last}'"
        end
        seed_ids.last
      end
    end

    def entitlements_data
      dict = entitlements
      if distribution_mode
        dict['application-identifier'] ||= seed_id + '.' + identifier
      else
        # Required for gdb.
        dict['get-task-allow'] = true if dict['get-task-allow'].nil?
      end
      Motion::PropertyList.to_s(dict)
    end

    def common_flags(platform)
      simulator_version = begin
        if platform == "iPhoneSimulator"
          m = deployment_target.match(/(\d+)/)
          if m[0].to_i >= 7
            " -mios-simulator-version-min=#{deployment_target}"
          else
            " -miphoneos-version-min=#{deployment_target}"
          end
        end
      end || ""
      super + simulator_version
    end

    def cflags(platform, cplusplus)
      super + " -g -fobjc-legacy-dispatch -fobjc-abi-version=2"
    end

    def ldflags(platform)
      ldflags = super
      ldflags << " -fobjc-arc" if deployment_target < '5.0'
      ldflags
    end

    def device_family_int(family)
      case family
        when :iphone then 1
        when :ipad then 2
        else
          App.fail "Unknown device_family value: `#{family}'"
      end
    end

    def device_family_string(family, target, retina)
      device = case family
        when :iphone, 1
          "iPhone"
        when :ipad, 2
          "iPad"
      end
      case retina
        when 'true'
          device + ((family == 1 and target >= '6.0') ? ' (Retina 4-inch)' : ' (Retina)')
        when '3.5'
          device + ' (Retina 3.5-inch)'
        when '4'
          device + ' (Retina 4-inch)'
        else
          device
      end
    end

    def device_family_ints
      ary = @device_family.is_a?(Array) ? @device_family : [@device_family]
      ary.map { |family| device_family_int(family) }
    end

    def interface_orientations_consts
      @interface_orientations.map do |ori|
        case ori
          when :portrait then 'UIInterfaceOrientationPortrait'
          when :landscape_left then 'UIInterfaceOrientationLandscapeLeft'
          when :landscape_right then 'UIInterfaceOrientationLandscapeRight'
          when :portrait_upside_down then 'UIInterfaceOrientationPortraitUpsideDown'
          else
            App.fail "Unknown interface_orientation value: `#{ori}'"
        end
      end
    end

    def background_modes_consts
      @background_modes.map do |mode|
        case mode
          when :audio then 'audio'
          when :location then 'location'
          when :voip then 'voip'
          when :newsstand_content then 'newsstand-content'
          when :external_accessory then 'external-accessory'
          when :bluetooth_central then 'bluetooth-central'
          else
            App.fail "Unknown background_modes value: `#{mode}'"
        end
      end
    end

    def status_bar_style_const
      case @status_bar_style
        when :default then 'UIStatusBarStyleDefault'
        when :black_translucent then 'UIStatusBarStyleBlackTranslucent'
        when :black_opaque then 'UIStatusBarStyleBlackOpaque'
        else
          App.fail "Unknown status_bar_style value: `#{@status_bar_style}'"
      end
    end

    def device_id
      @device_id ||= begin
        deploy = File.join(App.config.bindir, 'ios/deploy')
        device_id = `#{deploy} -D`.strip
        if device_id.empty?
          App.fail "Can't find an iOS device connected on USB"
        end
        device_id
      end
    end

    def app_bundle(platform)
      File.join(versionized_build_dir(platform), bundle_name + '.app')
    end

    def app_bundle_executable(platform)
      File.join(app_bundle(platform), name)
    end

    def app_resources_dir(platform)
      app_bundle(platform)
    end

    def fonts
      @fonts ||= begin
        resources_dirs.flatten.inject([]) do |fonts, dir|
          if File.exist?(dir)
            Dir.chdir(dir) do
              fonts.concat(Dir.glob('*.{otf,ttf}'))
            end
          else
            fonts
          end
        end
      end
    end

    def info_plist_data
      ios_version_to_build = lambda do |vers|
        # XXX we should retrieve these values programmatically.
        case vers
          when '4.3'; '8F191m'
          when '5.0'; '9A334'
          when '5.1'; '9B176'
          else; '10A403' # 6.0 or later
        end
      end
      Motion::PropertyList.to_s({
        'MinimumOSVersion' => deployment_target,
        'CFBundleResourceSpecification' => 'ResourceRules.plist',
        'CFBundleSupportedPlatforms' => [deploy_platform],
        'CFBundleIconFiles' => icons,
        'CFBundleIcons' => {
          'CFBundlePrimaryIcon' => {
            'CFBundleIconFiles' => icons,
            'UIPrerenderedIcon' => prerendered_icon,
          }
        },
        'UIAppFonts' => fonts,
        'UIDeviceFamily' => device_family_ints.map { |x| x.to_s },
        'UISupportedInterfaceOrientations' => interface_orientations_consts,
        'UIStatusBarStyle' => status_bar_style_const,
        'UIBackgroundModes' => background_modes_consts,
        'DTXcode' => begin
          vers = xcode_version[0].gsub(/\./, '')
          if vers.length == 2
            '0' + vers + '0'
          else
            '0' + vers
          end
        end,
        'DTXcodeBuild' => xcode_version[1],
        'DTSDKName' => "iphoneos#{sdk_version}",
        'DTSDKBuild' => ios_version_to_build.call(sdk_version),
        'DTPlatformName' => 'iphoneos',
        'DTCompiler' => 'com.apple.compilers.llvm.clang.1_0',
        'DTPlatformVersion' => sdk_version,
        'DTPlatformBuild' => ios_version_to_build.call(sdk_version)
      }.merge(generic_info_plist).merge(dt_info_plist).merge(info_plist))
    end

    def manifest_plist_data
      return nil if manifest_assets.empty?
      Motion::PropertyList.to_s({
        'items' => [
          { 'assets' => manifest_assets,
            'metadata' => {
              'bundle-identifier' => identifier,
              'bundle-version' => @version,
              'kind' => 'software',
              'title' => @name
            } }
        ]
      })
    end

    def supported_sdk_versions(versions)
      versions.reverse.find { |vers| File.exist?(datadir(vers)) }
    end

    def main_cpp_file_txt(spec_objs)
      main_txt = <<EOS
#import <UIKit/UIKit.h>

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
    // Give a bit of time for the simulator to attach...
    [self performSelector:@selector(runSpecs) withObject:nil afterDelay:0.3];
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
    int retval = 0;
    try {
EOS
      main_txt << "[SpecLauncher launcher];\n" if spec_mode
      main_txt << <<EOS
        RubyMotionInit(argc, argv);
EOS
      main_txt << <<EOS
        retval = UIApplicationMain(argc, argv, nil, @"#{delegate_class}");
        rb_exit(retval);
    }
    catch (...) {
	rb_rb2oc_exc_handler();
    }
    [pool release];
    return retval;
}
EOS
    end
  end
end; end
