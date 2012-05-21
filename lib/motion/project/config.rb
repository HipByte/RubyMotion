# Copyright (C) 2012, HipByte SPRL. All Rights Reserved.
#
# This file is subject to the terms and conditions of the End User License
# Agreement accompanying the package this file is a part of.

module Motion; module Project
  class Config
    VARS = []

    def self.variable(*syms)
      syms.each do |sym|
        attr_accessor sym
        VARS << sym.to_s
      end
    end

    class Deps < Hash
      def []=(key, val)
        key = relpath(key)
        val = [val] unless val.is_a?(Array)
        val = val.map { |x| relpath(x) }
        super
      end

      def relpath(path)
        /^\./.match(path) ? path : File.join('.', path)
      end
    end

    variable :files, :xcode_dir, :sdk_version, :deployment_target, :frameworks,
      :libs, :delegate_class, :name, :build_dir, :resources_dir, :specs_dir,
      :identifier, :codesign_certificate, :provisioning_profile,
      :device_family, :interface_orientations, :version, :icons,
      :prerendered_icon, :seed_id, :entitlements, :fonts

    attr_accessor :spec_mode

    def initialize(project_dir, build_mode)
      @project_dir = project_dir
      @files = Dir.glob(File.join(project_dir, 'app/**/*.rb'))
      @dependencies = {}
      @frameworks = ['UIKit', 'Foundation', 'CoreGraphics']
      @libs = []
      @delegate_class = 'AppDelegate'
      @name = 'Untitled'
      @resources_dir = File.join(project_dir, 'resources')
      @build_dir = File.join(project_dir, 'build')
      @specs_dir = File.join(project_dir, 'spec')
      @device_family = :iphone
      @bundle_signature = '????'
      @interface_orientations = [:portrait, :landscape_left, :landscape_right]
      @version = '1.0'
      @icons = []
      @prerendered_icon = false
      @vendor_projects = []
      @entitlements = {}
      @spec_mode = false
      @build_mode = build_mode
    end

    def variables
      map = {}
      VARS.each do |sym|
        map[sym] =
          begin
            send(sym)
          rescue Exception
            'Error'
          end
      end
      map
    end

    def xcode_dir
      @xcode_dir ||= begin
        xcode_dot_app_path = '/Applications/Xcode.app/Contents/Developer'

        # First, honor /usr/bin/xcode-select
	xcodeselect = '/usr/bin/xcode-select'
        if File.exist?(xcodeselect)
          path = `#{xcodeselect} -print-path`.strip
          if path != xcode_dot_app_path and File.exist?(xcode_dot_app_path)
            @xcode_error_printed ||= false
            $stderr.puts(<<EOS) unless @xcode_error_printed
===============================================================================
It appears that you have a version of Xcode installed in /Applications that has
not been set as the default version. It is possible that RubyMotion may be
using old versions of certain tools which could eventually cause issues.

To fix this problem, you can type the following command in the terminal:
    $ sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
===============================================================================
EOS
            @xcode_error_printed = true
          end
          return path if File.exist?(path)
        end

        # Since xcode-select is borked, we assume the user installed Xcode
        # as an app (new in Xcode 4.3).
        return xcode_dot_app_path if File.exist?(xcode_dot_app_path)

        App.fail "Can't locate any version of Xcode on the system."
      end
    end

    def locate_binary(name)
      [File.join(xcode_dir, 'usr/bin'), '/usr/bin'].each do |dir|
        path = File.join(dir, name)
        return path if File.exist?(path)
      end
      App.fail "Can't locate binary `#{name}' on the system."
    end

    def validate
      # Xcode version
      ary = `#{locate_binary('xcodebuild')} -version`.scan(/Xcode\s+([^\n]+)\n/)
      if ary and ary[0] and xcode_version = ary[0][0]
        App.fail "Xcode 4.x or greater is required" if xcode_version < '4.0'
      end

      # sdk_version
      ['iPhoneSimulator', 'iPhoneOS'].each do |platform|
        sdk_path = File.join(platforms_dir, platform + '.platform',
            "Developer/SDKs/#{platform}#{sdk_version}.sdk")
        unless File.exist?(sdk_path)
          App.fail "Can't locate #{platform} SDK #{sdk_version} at `#{sdk_path}'" 
        end
      end

      # deployment_target
      if deployment_target > sdk_version
        App.fail "Deployment target `#{deployment_target}' must be equal or lesser than SDK version `#{sdk_version}'"
      end
      unless File.exist?(datadir)
        App.fail "iOS deployment target #{deployment_target} is not supported by this version of RubyMotion"
      end
    end

    def build_dir
      unless File.directory?(@build_dir)
        tried = false
        begin
          FileUtils.mkdir_p(@build_dir)
        rescue Errno::EACCES
          raise if tried
          require 'digest/sha1'
          hash = Digest::SHA1.hexdigest(File.expand_path(project_dir))
          tmp = File.join(ENV['TMPDIR'], hash)
          App.warn "Cannot create build_dir `#{@build_dir}'. Check the permissions. Using a temporary build directory instead: `#{tmp}'"
          @build_dir = tmp
          tried = true
          retry
        end
      end
      @build_dir
    end

    def build_mode_name
      @build_mode.to_s.capitalize
    end

    def development?
      @build_mode == :development
    end

    def release?
      @build_mode == :release
    end

    def development
      yield if development?
    end

    def release
      yield if release?
    end

    def versionized_build_dir(platform)
      File.join(build_dir, platform + '-' + deployment_target + '-' + build_mode_name)
    end

    attr_reader :project_dir

    def project_file
      File.join(@project_dir, 'Rakefile')
    end

    def files_dependencies(deps_hash)
      res_path = lambda do |x|
        path = /^\./.match(x) ? x : File.join('.', x)
        unless @files.include?(path)
          App.fail "Can't resolve dependency `#{x}'"
        end
        path
      end
      deps_hash.each do |path, deps|
        deps = [deps] unless deps.is_a?(Array)
        @dependencies[res_path.call(path)] = deps.map(&res_path)
      end
    end

    attr_reader :vendor_projects

    def vendor_project(path, type, opts={})
      @vendor_projects << Motion::Project::Vendor.new(path, type, self, opts)
    end

    def unvendor_project(path)
      @vendor_projects.delete_if { |x| x.path == path }
    end

    def file_dependencies(file)
      deps = @dependencies[file]
      if deps
        deps = deps.map { |x| file_dependencies(x) }
      else
        deps = [] 
      end
      deps << file
      deps 
    end

    def ordered_build_files
      @ordered_build_files ||= begin
        flat_deps = @files.map { |file| file_dependencies(file) }.flatten
        paths = flat_deps.dup
        flat_deps.each do |path|
          n = paths.count(path)
          if n > 1
            (n - 1).times { paths.delete_at(paths.rindex(path)) }
          end
        end
        paths
      end
    end

    def frameworks_dependencies
      @frameworks_dependencies ||= begin
        # Compute the list of frameworks, including dependencies, that the project uses.
        deps = []
        slf = File.join(sdk('iPhoneSimulator'), 'System', 'Library', 'Frameworks')
        frameworks.each do |framework|
          framework_path = File.join(slf, framework + '.framework', framework)
          if File.exist?(framework_path)
            `#{locate_binary('otool')} -L \"#{framework_path}\"`.scan(/\t([^\s]+)\s\(/).each do |dep|
              # Only care about public, non-umbrella frameworks (for now).
              if md = dep[0].match(/^\/System\/Library\/Frameworks\/(.+)\.framework\/(.+)$/) and md[1] == md[2]
                deps << md[1]
              end
            end
          end
          deps << framework
        end
        deps.uniq
      end
    end

    def bridgesupport_files
      @bridgesupport_files ||= begin
        bs_files = []
        deps = ['RubyMotion'] + frameworks_dependencies
        deps.each do |framework|
          bs_path = File.join(datadir, 'BridgeSupport', framework + '.bridgesupport')
          if File.exist?(bs_path)
            bs_files << bs_path
          end
        end
        bs_files
      end
    end

    def spec_files
      Dir.glob(File.join(specs_dir, '**', '*.rb'))
    end

    def motiondir
      @motiondir ||= File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
    end

    def bindir
      File.join(motiondir, 'bin')
    end

    def datadir(target=deployment_target)
      File.join(motiondir, 'data', target)
    end

    def platforms_dir
      File.join(xcode_dir, 'Platforms')
    end

    def platform_dir(platform)
      File.join(platforms_dir, platform + '.platform')
    end

    def sdk_version
      @sdk_version ||= begin
        versions = Dir.glob(File.join(platforms_dir, 'iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk')).map do |path|
          File.basename(path).scan(/iPhoneOS(.*)\.sdk/)[0][0]
        end
        if versions.size == 0
          App.fail "Can't find an iOS SDK in `#{platforms_dir}'"
        end
        supported_vers = versions.reverse.find { |vers| File.exist?(datadir(vers)) }
        unless supported_vers
          App.fail "RubyMotion doesn't support any of these SDK versions: #{versions.join(', ')}"
        end
        supported_vers
      end
    end

    def deployment_target
      @deployment_target ||= sdk_version
    end

    def sdk(platform)
      File.join(platform_dir(platform), 'Developer/SDKs',
        platform + sdk_version + '.sdk')
    end

    def locate_compiler(platform, *execs)
      paths = [File.join(platform_dir(platform), 'Developer/usr/bin')]
      paths.unshift File.join(xcode_dir, 'Toolchains/XcodeDefault.xctoolchain/usr/bin') if platform == 'iPhoneSimulator'

      execs.each do |exec|
        paths.each do |path|
          cc = File.join(path, exec)
          return cc if File.exist?(cc)
        end
      end
      App.fail "Can't locate compilers for platform `#{platform}'"
    end

    def archs(platform)
      Dir.glob(File.join(datadir, platform, '*.bc')).map do |path|
        path.scan(/kernel-(.+).bc$/)[0][0]
      end
    end

    def arch_flags(platform)
      archs(platform).map { |x| "-arch #{x}" }.join(' ')
    end

    def common_flags(platform)
      "#{arch_flags(platform)} -isysroot \"#{sdk(platform)}\" -miphoneos-version-min=#{deployment_target} -F#{sdk(platform)}/System/Library/Frameworks"
    end

    def cflags(platform, cplusplus)
      "#{common_flags(platform)} -fexceptions -fblocks -fobjc-legacy-dispatch -fobjc-abi-version=2" + (cplusplus ? '' : ' -std=c99')
    end

    def ldflags(platform)
      common_flags(platform)
    end

    def bundle_name
      @name + (spec_mode ? '_spec' : '')
    end

    def app_bundle(platform)
      File.join(versionized_build_dir(platform), bundle_name + '.app')
    end

    def app_bundle_dsym(platform)
      File.join(versionized_build_dir(platform), bundle_name + '.dSYM')
    end

    def app_bundle_executable(platform)
      File.join(app_bundle(platform), name)
    end

    def archive
      File.join(versionized_build_dir('iPhoneOS'), bundle_name + '.ipa')
    end

    def identifier
      @identifier ||= "com.yourcompany.#{@name.gsub(/\s/, '')}"
    end

    def device_family_int(family)
      case family
        when :iphone then 1
        when :ipad then 2
        else
          App.fail "Unknown device_family value: `#{family}'"
      end
    end

    def device_family_string(family, retina)
      device = case family
        when :iphone, 1
          "iPhone"
        when :ipad, 2
          "iPad"
      end
      retina ? device + " (Retina)" : device
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

    def info_plist
      @info_plist ||= {
        'BuildMachineOSBuild' => `sw_vers -buildVersion`.strip,
        'MinimumOSVersion' => deployment_target,
        'CFBundleDevelopmentRegion' => 'en',
        'CFBundleName' => @name,
        'CFBundleDisplayName' => @name,
        'CFBundleExecutable' => @name, 
        'CFBundleIdentifier' => identifier,
        'CFBundleInfoDictionaryVersion' => '6.0',
        'CFBundlePackageType' => 'APPL',
        'CFBundleResourceSpecification' => 'ResourceRules.plist',
        'CFBundleShortVersionString' => @version,
        'CFBundleSignature' => @bundle_signature,
        'CFBundleSupportedPlatforms' => ['iPhoneOS'],
        'CFBundleVersion' => @version,
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
        'UIStatusBarStyle' => 'UIStatusBarStyleDefault',
        'DTXcode' => '0431',
        'DTSDKName' => 'iphoneos5.0',
        'DTSDKBuild' => '9A334',
        'DTPlatformName' => 'iphoneos',
        'DTCompiler' => 'com.apple.compilers.llvm.clang.1_0',
        'DTPlatformVersion' => '5.1',
        'DTXcodeBuild' => '4E1019',
        'DTPlatformBuild' => '9B176'
      }
    end

    def info_plist_data
      Motion::PropertyList.to_s(info_plist)
    end

    def pkginfo_data
      "AAPL#{@bundle_signature}"
    end

    def codesign_certificate
      @codesign_certificate ||= begin
        cert_type = (development? ? 'Developer' : 'Distribution')
        certs = `/usr/bin/security -q find-certificate -a`.scan(/"iPhone #{cert_type}: [^"]+"/).uniq
        if certs.size == 0
          App.fail "Can't find an iPhone Developer certificate in the keychain"
        elsif certs.size > 1
          App.warn "Found #{certs.size} iPhone Developer certificates in the keychain. Set the `codesign_certificate' project setting. Will use the first certificate: `#{certs[0]}'"
        end
        certs[0][1..-2] # trim trailing `"` characters
      end 
    end

    def device_id
      @device_id ||= begin
        deploy = File.join(App.config.bindir, 'deploy')
        device_id = `#{deploy} -D`.strip
        if device_id.empty?
          App.fail "Can't find an iOS device connected on USB"
        end
        device_id
      end
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
      if release?
        dict['application-identifier'] ||= seed_id + '.' + identifier
      end
      Motion::PropertyList.to_s(dict)
    end

    def fonts
      @fonts ||= begin
        if File.exist?(resources_dir)
          Dir.chdir(resources_dir) do
            Dir.glob('*.{otf,ttf}')
          end
        else
          []
        end
      end
    end
  end
end; end
