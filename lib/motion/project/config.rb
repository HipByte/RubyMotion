require 'motion/plist'

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

    variable :files, :platforms_dir, :sdk_version, :frameworks, :libs,
      :delegate_class, :name, :build_dir, :resources_dir, :identifier,
      :codesign_certificate, :provisioning_profile, :device_family,
      :interface_orientations, :version, :icons, :prerendered_icon,
      :seed_id, :entitlements

    def initialize(project_dir)
      @project_dir = project_dir
      @files = Dir.glob(File.join(project_dir, 'app/**/*.rb'))
      @dependencies = {}
      @platforms_dir = '/Developer/Platforms'
      @frameworks = ['UIKit', 'Foundation', 'CoreGraphics']
      @libs = []
      @delegate_class = 'AppDelegate'
      @name = 'Untitled'
      @resources_dir = File.join(project_dir, 'resources')
      @build_dir = File.join(project_dir, 'build')
      @device_family = :iphone
      @bundle_signature = '????'
      @interface_orientations = [:portrait, :landscape_left, :landscape_right]
      @version = '1.0'
      @icons = []
      @prerendered_icon = false
      @vendor_projects = []
      @entitlements = {}
    end

    def variables
      map = {}
      VARS.each do |sym|
        val = send(sym) rescue "ERROR"
        map[sym] = val
      end
      map
    end

    def validate
      # sdk_version
      ['iPhoneSimulator', 'iPhoneOS'].each do |platform|
        sdk_path = File.join(platforms_dir, platform + '.platform',
            "Developer/SDKs/#{platform}#{sdk_version}.sdk")
        unless File.exist?(sdk_path)
          $stderr.puts "Can't locate #{platform} SDK #{sdk_version} at `#{sdk_path}'" 
          exit 1
        end
      end
      unless File.exist?(datadir)
        $stderr.puts "iOS SDK #{sdk_version} is not supported by this version of RubyMotion"
        exit 1
      end
    end

    def build_dir
      tried = false
      begin
        FileUtils.mkdir_p(@build_dir)
      rescue Errno::EACCES
        raise if tried
        require 'digest/sha1'
        hash = Digest::SHA1.hexdigest(File.expand_path(project_dir))
        tmp = File.join(ENV['TMPDIR'], hash)
        $stderr.puts "Cannot create build_dir `#{@build_dir}'. Check the permissions. Using temporary build directory instead: `#{tmp}'"
        @build_dir = tmp
        tried = true
        retry
      end
      @build_dir
    end

    attr_reader :project_dir

    def project_file
      File.join(@project_dir, 'Rakefile')
    end

    def files_dependencies(deps_hash)
      p = lambda { |x| /^\./.match(x) ? x : File.join('.', x) }
      deps_hash.each do |path, deps|
        deps = [deps] unless deps.is_a?(Array)
        @dependencies[p.call(path)] = deps.map(&p)
      end
    end

    attr_reader :vendor_projects

    def vendor_project(path, type, opts={})
      @vendor_projects << Motion::Project::Vendor.new(path, type, self, opts)
    end

    def ordered_build_files
      ary = []
      @files.each do |file|
        deps = @dependencies[file]
        if deps
          deps.each do |dep|
            ary << dep unless ary.index(dep)
          end
        end
        ary << file unless ary.index(file)
      end
      ary
    end

    def motiondir
      File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
    end

    def bindir
      File.join(motiondir, 'bin')
    end

    def datadir
      File.join(motiondir, 'data', sdk_version)
    end

    def platform_dir(platform)
      File.join(@platforms_dir, platform + '.platform')
    end

    def sdk_version
      @sdk_version ||= begin
        versions = Dir.glob(File.join(platforms_dir, 'iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk')).map do |path|
          File.basename(path).scan(/iPhoneOS(.*)\.sdk/)[0][0]
        end
        if versions.size == 0
          $stderr.puts "Can't find an iOS SDK in `#{platforms_dir}'"
          exit 1
        #elsif versions.size > 1
        #  $stderr.puts "found #{versions.size} SDKs, will use the latest one"
        end
        versions.max
      end
    end

    def sdk(platform)
      File.join(platform_dir(platform), 'Developer/SDKs',
        platform + sdk_version + '.sdk')
    end

    def app_bundle(platform)
      File.join(@build_dir, platform, @name + '.app')
    end

    def archive
      File.join(@build_dir, @name + '.ipa')
    end

    def identifier
      @identifier ||= "com.yourcompany.#{@name.gsub(/\s/, '')}"
    end

    def device_family_ints
      ary = @device_family.is_a?(Array) ? @device_family : [@device_family]
      ary.map do |family|
        case family
          when :iphone then 1
          when :ipad then 2
          else
            $stderr.puts "Unknown device_family value: `#{family}'"
            exit 1
        end
      end
    end

    def interface_orientations_consts
      @interface_orientations.map do |ori|
        case ori
          when :portrait then 'UIInterfaceOrientationPortrait'
          when :landscape_left then 'UIInterfaceOrientationLandscapeLeft'
          when :landscape_right then 'UIInterfaceOrientationLandscapeRight'
          when :portrait_upside_down then 'UIInterfaceOrientationPortraitUpsideDown'
          else
            $stderr.puts "Unknown interface_orientation value: `#{ori}'"
            exit 1
        end
      end
    end

    def info_plist
      @info_plist ||= {
        'BuildMachineOSBuild' => `sw_vers -buildVersion`.strip,
        'MinimumOSVersion' => sdk_version,
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
        'UIDeviceFamily' => device_family_ints.map { |x| x.to_s },
        'UISupportedInterfaceOrientations' => interface_orientations_consts
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
        certs = `/usr/bin/security -q find-certificate -a`.scan(/"iPhone Developer: [^"]+"/).uniq
        if certs.size == 0
          $stderr.puts "Can't find an iPhone Developer certificate in the keychain"
          exit 1
        elsif certs.size > 1
          $stderr.puts "Found #{certs.size} iPhone Developer certificates, will use the first one: `#{certs[0]}'"
        end
        certs[0][1..-2] # trim trailing `"` characters
      end 
    end

    def provisioning_profile
      @provisioning_profile ||= begin
        paths = Dir.glob(File.expand_path("~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision"))
        if paths.size == 0
          $stderr.puts "Can't find a provisioning profile"
          exit 1
        elsif paths.size > 1
          $stderr.puts "Found #{paths.size} provisioning profiles, will use the first one: `#{paths[0]}'"
        end
        paths[0]
      end
    end

    def seed_id
      @seed_id ||= begin
        txt = File.read(provisioning_profile)
        seed_ids = txt.scan(/<key>\s*ApplicationIdentifierPrefix\s*<\/key>\s*<array>(\s*<string>\s*([^<\s]+)\s*<\/string>)+\s*<\/array>/).map { |ary| ary[1] }
        if seed_ids.size == 0
          $stderr.puts "Can't find an application seed ID in the provisioning profile"
          exit 1
        elsif seed_ids.size > 1
          $stderr.puts "Found #{seed_ids.size} seed IDs in the provisioning profile, will use the last one: `#{seed_ids.last}'"
        end
        seed_ids.last
      end
    end

    def entitlements_data
      Motion::PropertyList.to_s(entitlements)
    end
  end
end; end
