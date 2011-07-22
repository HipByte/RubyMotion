module Rubixir
  class Config
    VARS = []

    def self.variable(*syms)
      syms.each do |sym|
        attr_accessor sym
        VARS << sym.to_s
      end
    end    

    variable :files, :platforms_dir, :sdk_version, :frameworks,
      :app_delegate_class, :app_name, :build_dir, :resources_dir,
      :codesign_certificate, :provisioning_profile

    def initialize(project_dir)
      @files = Dir.glob(File.join(project_dir, 'app/**/*.rb'))
      @platforms_dir = '/Developer/Platforms'
      @frameworks = ['UIKit', 'Foundation', 'CoreGraphics']
      @app_delegate_class = 'AppDelegate'
      @app_name = 'My App'
      @build_dir = File.join(project_dir, 'build')
      @resources_dir = File.join(project_dir, 'resources')
      @bundle_signature = '????'
    end

    def variables
      map = {}
      VARS.each do |sym|
        val = send(sym) rescue "ERROR"
        map[sym] = val
      end
      map
    end

    def datadir
      File.expand_path(File.join(File.dirname(__FILE__), '../../../data'))
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
          $stderr.puts "can't locate any iPhone SDK"
          exit 1
        elsif versions.size > 1
          $stderr.puts "found #{versions.size} SDKs, will use the latest one"
        end
        versions.max
      end
    end

    def sdk(platform)
      File.join(platform_dir(platform), 'Developer/SDKs',
        platform + sdk_version + '.sdk')
    end

    def app_bundle(platform, exec=false)
      path = File.join(@build_dir, platform, @app_name + '.app')
      path = File.join(path, @app_name) if exec
      path
    end

    def archive
      File.join(@build_dir, @app_name + '.ipa')
    end

    def plist_data
<<DATA
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildMachineOSBuild</key>
	<string>#{`sw_vers -buildVersion`.strip}</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>#{@app_name}</string>
	<key>CFBundleExecutable</key>
	<string>#{@app_name}</string>
	<key>CFBundleIdentifier</key>
	<string>com.omgwtf.#{@app_name}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>#{@app_name}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleResourceSpecification</key>
	<string>ResourceRules.plist</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSignature</key>
	<string>#{@bundle_signature}</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>iPhoneOS</string>
	</array>
	<key>CFBundleVersion</key>
	<string>1.0</string>
	<key>DTCompiler</key>
	<string>com.apple.compilers.llvmgcc42</string>
	<key>DTPlatformBuild</key>
	<string>8H7</string>
	<key>DTPlatformName</key>
	<string>iphoneos</string>
	<key>DTPlatformVersion</key>
	<string>#{sdk_version}</string>
	<key>DTSDKBuild</key>
	<string>8H7</string>
	<key>DTSDKName</key>
	<string>iphoneos#{sdk_version}</string>
	<key>DTXcode</key>
	<string>0402</string>
	<key>DTXcodeBuild</key>
	<string>4A2002a</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>MinimumOSVersion</key>
	<string>#{sdk_version}</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
	</array>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
DATA
    end

    def pkginfo_data
      "AAPL#{@bundle_signature}"
    end

    def codesign_certificate
      @codesign_certificate ||= begin
        certs = `/usr/bin/security -q find-certificate -a`.scan(/"iPhone Developer: [^"]+"/).uniq
        if certs.size == 0
          $stderr.puts "can't find any iPhone Developer certificate in the keychain"
          exit 1
        elsif certs.size > 1
          $stderr.puts "found #{certs.size} iPhone Developer certificates, will use the first one (#{certs[0]})"
        end
        certs[0][1..-2] # trim trailing `"` characters
      end 
    end

    def provisioning_profile
      @provisioning_profile ||= begin
        paths = Dir.glob(File.expand_path("~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision"))
        if paths.size == 0
          $stderr.puts "can't find any provisioning profile"
          exit 1
        elsif paths.size > 1
          $stderr.puts "found #{paths.size} provisioning profiles, will use the first one (#{paths[0]})"
        end
        paths[0]
      end
    end
  end
end
