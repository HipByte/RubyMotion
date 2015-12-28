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

      if Motion::Project::Config.starter?
        self.resources_dirs << File.join(File.dirname(__FILE__), 'launch_image')
        self.info_plist['UILaunchStoryboardName'] = 'launch_screen'
      end
    end

    def platforms; ['iPhoneSimulator', 'iPhoneOS']; end
    def local_platform; 'iPhoneSimulator'; end
    def deploy_platform; 'iPhoneOS'; end

    def archs
      @archs ||= begin
        # No longer build for armv7s by default.
        archs = super
        archs['iPhoneOS'].delete('armv7s') if archs['iPhoneOS']
        archs
      end
    end

    # @return [String, nil] The path to the asset bundle that contains launch
    #         images, if any.
    #
    def launch_images_asset_bundle
      launch_images_asset_bundles = assets_bundles.map { |b| Dir.glob(File.join(b, '*.launchimage')) }.flatten
      if launch_images_asset_bundles.size > 1
        App.warn "Found #{launch_images_asset_bundles.size} launch image sets across all " \
                 "xcasset bundles. Only the first one (alphabetically) will be used."
      end
      launch_images_asset_bundles.sort.first
    end

    # @return [String, nil] The name of the launch image set, without any
    #         extension.
    #
    def launch_image_name_from_asset_bundle
      if bundle = launch_images_asset_bundle
        File.basename(bundle, '.launchimage')
      end
    end

    # Assigns the launch image information, found in the `Info.plist` generated
    # by compiling the asset bundles, to the `info_plist`’s `UILaunchImages`.
    #
    # @return [void]
    #
    def add_images_from_asset_bundles(platform)
      super
      if launch_images_asset_bundle
        path = asset_bundle_partial_info_plist_path(platform)
        if File.exist?(path)
          content = `/usr/libexec/PlistBuddy -c 'Print :UILaunchImages' "#{path}" 2>&1`.strip
          if $?.success?
            images = []
            current_image = nil
            content.split("\n")[1..-2].each do |line|
              case line.strip
              when 'Dict {'
                current_image = {}
              when '}'
                images << current_image
                current_image = nil
              when /(\w+) = (.+)/
                current_image[$1] = $2
              end
            end
            unless images.empty?
              info_plist['UILaunchImages'] = images
            end
          end
        end
      end
    end

    def validate
      # icons
      if !(icons.is_a?(Array) and icons.all? { |x| x.is_a?(String) })
        App.fail "app.icons should be an array of strings."
      end

      # manifest_assets
      if !(manifest_assets.is_a?(Array) and manifest_assets.all? { |x| x.is_a?(Hash) and x.keys.include?(:kind) and x.keys.include?(:url) })
        App.fail "app.manifest_assets should be an array of hashes with values for the :kind and :url keys"
      end

      if Motion::Project::Config.starter?
        # RubyMotion Starter must have the launch screen.
        launch_screen_err_msg = "You are using RubyMotion Starter. You are not allowed to remove or edit the RubyMotion splash screen from your app, but you can purchase a paid subscription to do so."
        if info_plist['UILaunchStoryboardName'] != 'launch_screen'
          App.fail launch_screen_err_msg
        end

        # Files must be intact.
        Dir.chdir(File.join(File.dirname(__FILE__), 'launch_image')) do
          IO.popen('shasum -c - >& /dev/null', 'w') do |io|
            io.puts <<EOS
6d0daeb80a5048120fd088e1a139d4d9e12906ec  ./launch_screen.png
0e890dd3684e5cb893c5128f5e95f9c33e535d32  ./launch_screen.storyboardc/01J-lp-oVM-view-Ze5-6b-2t3.nib
9f6b7c82c0e97c4e979211b7d69ec84094714f15  ./launch_screen.storyboardc/Info.plist
3888d250465ac017d7b21fcb51477fcddc6a1b6c  ./launch_screen.storyboardc/UIViewController-01J-lp-oVM.nib
EOS
          end
          unless $?.success?
            App.fail launch_screen_err_msg
          end
        end

        # Deployment target must not change.
        if self.deployment_target != '9.2' or (self.info_plist['MinimumOSVersion'] and self.info_plist['MinimumOSVersion'] != '9.2')
          App.fail "You are using RubyMotion Starter. Only iOS 9.2 is supported in this release. If you would like to target older or newer (in beta) versions of iOS you can purchase a paid subscription."
        end
      end

      super
    end

    def locate_compiler(platform, *execs)
      paths = [File.join(platform_dir(platform), 'Developer/usr/bin')]
      paths.unshift File.join(xcode_dir, 'Toolchains/XcodeDefault.xctoolchain/usr/bin')

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

    # The codesign certificate, where certificates prefixed with `iOS` are
    # preferred over those prefixed with `iPhone`.
    #
    # @return [String] The name of the certificate.
    #
    def codesign_certificate
      super('iOS', 'iPhone')
    end

    def provisioning_profile(name = /iOS\s?Team Provisioning Profile/)
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
      File.expand_path(@provisioning_profile)
    end

    def read_provisioned_profile_array(key)
      text = File.read(provisioning_profile)
      text.force_encoding('binary') if RUBY_VERSION >= '1.9.0'
      text.scan(/<key>\s*#{key}\s*<\/key>\s*<array>(.*?)\s*<\/array>/m)[0][0].scan(/<string>(.*?)<\/string>/).map { |str| str[0].strip }
    end
    private :read_provisioned_profile_array

    def read_provisioned_profile_boolean(key)
      text = File.read(provisioning_profile)
      text.force_encoding('binary') if RUBY_VERSION >= '1.9.0'
      case text.scan(/<key>\s*#{key}\s*<\/key>\s*<(true|false)\/>/m)[0]
      when ['true']
        true
      when ['false']
        false
      else
        nil
      end
    end
    private :read_provisioned_profile_boolean

    def provisions_all_devices?
      @provisions_all_devices ||= !!read_provisioned_profile_boolean('ProvisionsAllDevices')
    end

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
      dict['application-identifier'] ||= seed_id + '.' + identifier
      unless distribution_mode
        # Required for gdb.
        dict['get-task-allow'] = true if dict['get-task-allow'].nil?
      end
      Motion::PropertyList.to_s(dict)
    end

    def common_flags(platform)
      super + cflag_version_min(platform)
    end

    def cflag_version_min(platform)
      flag = " -miphoneos-version-min=#{deployment_target}"
      if platform == "iPhoneSimulator"
        ver = xcode_version[0].match(/(\d+)/)
        if ver[0].to_i >= 5
          flag = " -mios-simulator-version-min=#{deployment_target}"
        end
      end
      flag
    end

    def cflags(platform, cplusplus)
      super + " -g -fobjc-legacy-dispatch -fobjc-abi-version=2"
    end

    def ldflags(platform)
      ldflags = super
      ldflags << " -fobjc-arc" if deployment_target < '5.0'
      ldflags
    end

    def bridgesupport_flags
      extra_flags = (osx_host_version >= Util::Version.new('10.7') && sdk_version < '7.0') ? '--no-64-bit' : ''
      "--format complete #{extra_flags}"
    end

    def bridgesupport_cflags
      a = sdk_version.scan(/(\d+)\.(\d+)/)[0]
      sdk_version_headers = ((a[0].to_i * 10000) + (a[1].to_i * 100)).to_s
      "-miphoneos-version-min=#{sdk_version} -D__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__=#{sdk_version_headers}"
    end

    def device_family_int(family)
      case family
        when :iphone then 1
        when :ipad then 2
        when :tv then 3
        else
          App.fail "Unknown device_family value: `#{family}'"
      end
    end

    def device_family_string(device_name, family, target, retina)
      device = case family
        when :iphone, 1
          "iPhone"
        when :ipad, 2
          "iPad"
      end

      ver = xcode_version[0].match(/(\d+)/)[0].to_i
      if ver >= 6
        (device_name.nil?) ? device + device_retina_xcode6_string(family, target, retina) : device_name
      elsif ver == 5
        device + device_retina_xcode5_string(family, target, retina)
      else
        device + device_retina_xcode4_string(family, target, retina)
      end
    end

    def device_retina_xcode4_string(family, target, retina)
      case retina
      when 'true'
        (family == 1 and target >= '6.0') ? ' (Retina 4-inch)' : ' (Retina)'
      when '3.5'
        ' (Retina 3.5-inch)'
      when '4'
        ' (Retina 4-inch)'
      else
        ''
      end
    end

    def device_retina_xcode5_string(family, target, retina)
      retina4_string = begin
        if (target >= '7.0' && App.config.archs['iPhoneSimulator'].include?("x86_64"))
          " Retina (4-inch 64-bit)"
        else
          " Retina (4-inch)"
        end
      end

      case retina
      when 'true'
        (family == 1 and target >= '6.0') ? retina4_string : ' Retina'
      when '3.5'
        ' Retina (3.5-inch)'
      when '4'
        ' Retina (4-inch)'
      else
        if target < '7.0'
          ''
        else
          (family == 1) ? retina4_string : ''
        end
      end
    end

    def device_retina_xcode6_string(family, target, retina)
      case retina
      when '3.5'
        ' 4s'
      when '4'
        ' 5s'
      else
        (family == 1) ? ' 6' : ' Air'
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
        when :light_content then 'UIStatusBarStyleLightContent'
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

    # @param [String] platform
    #        The platform identifier that's being build for, such as
    #        `iPhoneSimulator` or `iPhoneOS`.
    #
    # @return [String] The path to the app bundle in the build directory.
    #
    def app_bundle(platform)
      File.join(versionized_build_dir(platform), bundle_filename)
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

    def launch_image_metadata(path)
      filename = File.basename(path, File.extname(path))
      filename_components = filename.split(/-|@|~/)
      name = filename_components.shift
      scale = (filename_components.find { |c| c =~ /\dx/ } || 1).to_i
      orientation = filename_components.find { |c| c =~ /Portrait|PortraitUpsideDown|Landscape|LandscapeLeft|LandscapeRight/ } || 'Portrait'
      expected_height = filename_components.find { |c| c =~ /\d+h/ }
      expected_height = expected_height.to_i if expected_height

      metadata = `/usr/bin/sips -g format -g pixelWidth -g pixelHeight '#{path}'`.strip

      format = metadata.match(/format: (\w+)/)[1]
      unless metadata.include?('format: png')
        App.fail "Launch Image `#{path}' not recognized as png file, but `#{format}' instead."
      end

      width = metadata.match(/pixelWidth: (\d+)/)[1].to_i
      height = metadata.match(/pixelHeight: (\d+)/)[1].to_i
      width /= scale
      height /= scale
      if expected_height && expected_height != height
        App.fail "Launch Image size (#{width}x#{height}) does not match the specified modifier `#{expected_height}h'."
      end

      {
        # For now I'm assuming that an image for an 'iOS 8'-only device, such as
        # iPhone 6, will work fine with a min OS version of 7.0.
        #
        # Otherwise we would also have to reflect on the data and infer whether
        # or not the device is a device such as the iPhone 6 and hardcode
        # devices.
        "UILaunchImageMinimumOSVersion" => "7.0",
        "UILaunchImageName" => filename,
        "UILaunchImageOrientation" => orientation,
        "UILaunchImageSize" => "{#{width}, #{height}}"
      }
    end

    # From iOS 7 and up we try to infer the launch images by looking for png
    # files that start with 'Default'.
    #
    def launch_images
      if Util::Version.new(deployment_target) >= Util::Version.new('7')
        images = resources_dirs.map do |dir|
          Dir.glob(File.join(dir, '{Default,LaunchImage}*.png')).map do |file|
            launch_image_metadata(file)
          end
        end.flatten.compact
        images unless images.empty?
      end
    end

    def merged_info_plist(platform)
      plist = super.merge({
        'MinimumOSVersion' => deployment_target,
        'CFBundleSupportedPlatforms' => [deploy_platform],
        'CFBundleIconFiles' => icons,
        'CFBundleIcons' => {
          'CFBundlePrimaryIcon' => {
            'CFBundleIconFiles' => icons,
            'UIPrerenderedIcon' => prerendered_icon,
          }
        },
        'UIAppFonts' => fonts,
        'UIDeviceFamily' => device_family_ints,
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
        'DTSDKName' => "#{platform.downcase}#{sdk_version}",
        'DTSDKBuild' => sdk_build_version(platform),
        'DTPlatformName' => platform.downcase,
        'DTCompiler' => 'com.apple.compilers.llvm.clang.1_0',
        'DTPlatformVersion' => sdk_version,
        'DTPlatformBuild' => sdk_build_version(platform),
      }) {|key, oldval, newval| oldval }
      # If the user has not explicitly specified launch images, try to find
      # them ourselves.
      if !plist.has_key?('UILaunchImages') && launch_images = self.launch_images
        plist['UILaunchImages'] = launch_images
      end
      plist
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
              'title' => name
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
    rb_exit(retval);
    [pool release];
    return retval;
}
EOS
    end
  end
end; end
