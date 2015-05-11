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

require 'pathname'
require 'motion/project/app'
require 'motion/util/version'

module Motion; module Project
  class Config
    include Rake::DSL if defined?(Rake) && Rake.const_defined?(:DSL)

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

    variable :name, :files, :build_dir, :specs_dir, :resources_dirs, :motiondir

    # Internal only.
    attr_accessor :build_mode, :spec_mode, :distribution_mode, :dependencies,
      :template, :detect_dependencies, :exclude_from_detect_dependencies,
      :opt_level, :custom_init_funcs

    ConfigTemplates = {}

    def self.register(template)
      ConfigTemplates[template] = self
    end

    def self.make(template, project_dir, build_mode)
      klass = ConfigTemplates[template]
      unless klass
        $stderr.puts "Config template `#{template}' not registered"
        exit 1
      end
      config = klass.new(project_dir, build_mode)
      config.template = template
      config
    end

    def initialize(project_dir, build_mode)
      @project_dir = project_dir
      @files = Dir.glob(File.join(project_dir, 'app/**/*.rb'))
      @build_mode = build_mode
      @name = 'Untitled'
      @resources_dirs = [File.join(project_dir, 'resources')]
      @build_dir = File.join(project_dir, 'build')
      @specs_dir = File.join(project_dir, 'spec')
      @dependencies = {}
      @detect_dependencies = true
      @exclude_from_detect_dependencies = []
      @custom_init_funcs = []
    end

    def osx_host_version
      @osx_host_version ||= Util::Version.new(`/usr/bin/sw_vers -productVersion`.strip)
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

    def setup_blocks
      @setup_blocks ||= []
    end

    def setup
      if @setup_blocks
        @setup_blocks.each { |b| b.call(self) }
        @setup_blocks = nil
        validate
      end
      self
    end

    def unescape_path(path)
      path.gsub('\\', '')
    end

    def escape_path(path)
      path.gsub(' ', '\\ ')
    end

    def locate_binary(name)
      [File.join(xcode_dir, 'usr/bin'), '/usr/bin'].each do |dir|
        path = File.join(dir, name)
        return escape_path(path) if File.exist?(path)
      end
      App.fail "Can't locate binary `#{name}' on the system."
    end

    def validate
      # Do nothing, for now.
    end

    def supported_versions
      @supported_versions ||= Dir.glob(File.join(motiondir, 'data', template.to_s, '[1-9]*')).select{|path| File.directory?(path)}.map do |path|
        File.basename path
      end
    end

    def resources_dir
      warn("`app.resources_dir' is deprecated; use `app.resources_dirs'");
      @resources_dirs.first
    end

    def resources_dir=(dir)
      warn("`app.resources_dir' is deprecated; use `app.resources_dirs'");
      @resources_dirs = [dir]
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

    def build_mode=(mode)
      @build_mode = mode
      @embed_dsym = (development? ? true : false)
      mode
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

    def opt_level
      @opt_level ||= case @build_mode
        when :development; 0
        when :release; 3
        else; 0
      end
    end

    attr_reader :project_dir

    def project_file
      File.join(@project_dir, 'Rakefile')
    end

    def files_dependencies(deps_hash)
      res_path = lambda do |x|
        path = /^\.{0,2}\//.match(x) ? x : File.join('.', x)
        unless @files.flatten.include?(path)
          App.fail "Can't resolve dependency `#{path}'"
        end
        path
      end
      deps_hash.each do |path, deps|
        deps = [deps] unless deps.is_a?(Array)
        @dependencies[res_path.call(path)] = deps.map(&res_path)
      end
    end

    def file_dependencies(file)
      # memorize the calculated file dependencies in order to reduce the time
      # detecting file dependencies.
      # http://hipbyte.myjetbrains.com/youtrack/issue/RM-466
      @known_dependencies ||= {}
      @known_dependencies[file] ||= begin
        deps = @dependencies[file] || []
        deps = deps.map { |x| file_dependencies(x) }.flatten.uniq
        deps << file
        deps
      end
    end

    def ordered_build_files
      @ordered_build_files ||= begin
        @files.flatten.map { |file| file_dependencies(file) }.flatten.uniq
      end
    end

    def spec_core_files
      @spec_core_files ||= begin
        # Core library + core helpers.
        Dir.chdir(File.join(File.dirname(__FILE__), '..')) do
          (['spec.rb'] +
          Dir.glob(File.join('spec', 'helpers', '*.rb')) +
          Dir.glob(File.join('project', 'template', App.template.to_s, 'spec-helpers', '*.rb'))).
            map { |x| File.expand_path(x) }
        end
      end
    end

    def spec_files
      @spec_files ||= begin
        # Project helpers.
        helpers = Dir.glob(File.join(specs_dir, 'helpers', '**', '*.rb'))
        # Project specs.
        specs = Dir.glob(File.join(specs_dir, '**', '*.rb')) - helpers
        if files_filter = ENV['files']
          # Filter specs we want to run. A filter can be either the basename of a spec file or its path.
          files_filter = files_filter.split(',')
          files_filter.map! { |x| File.exist?(x) ? File.expand_path(x) : x }
          specs.delete_if { |x| [File.expand_path(x), File.basename(x, '.rb'), File.basename(x, '_spec.rb')].none? { |p| files_filter.include?(p) } }
        end
        spec_core_files + helpers + specs
      end
    end

    def motiondir
      @motiondir ||= File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
    end

    def bindir
      File.join(motiondir, 'bin')
    end

    def datadir(target=deployment_target)
      File.join(motiondir, 'data', template.to_s, target)
    end

    def strip_args
      ''
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
      paths.unshift File.join(xcode_dir, 'Toolchains/XcodeDefault.xctoolchain/usr/bin')

      execs.each do |exec|
        paths.each do |path|
          cc = File.join(path, exec)
          return cc if File.exist?(cc)
        end
      end
      App.fail "Can't locate compilers for platform `#{platform}'"
    end

    def archs
      @archs ||= begin
        h = {}
        %w{iPhoneSimulator iPhoneOS}.each do |platform|
          h[platform] = Dir.glob(File.join(datadir, platform, '*.bc')).map do |path|
            path.scan(/kernel-(.+).bc$/)[0][0]
          end
        end
        h
      end
    end

    def arch_flags(platform)
      archs[platform].map { |x| "-arch #{x}" }.join(' ')
    end

    def common_flags(platform)
      "#{arch_flags(platform)} -isysroot \"#{sdk(platform)}\" -miphoneos-version-min=#{deployment_target} -F#{sdk(platform)}/System/Library/Frameworks"
    end

    def cflags(platform, cplusplus)
      "#{common_flags(platform)} -fexceptions -fblocks -fobjc-legacy-dispatch -fobjc-abi-version=2" + (cplusplus ? '' : ' -std=c99')
    end

    def ldflags(platform)
      ldflags = common_flags(platform)
      ldflags << " -fobjc-arc" if deployment_target < '5.0'
      ldflags
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
      spec_mode ? @identifier + '_spec' : @identifier
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

    def info_plist
      @info_plist
    end

    def dt_info_plist
{
}
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
        'CFBundleShortVersionString' => @short_version,
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
      }.merge(dt_info_plist).merge(info_plist))
    end

    def pkginfo_data
      "AAPL#{@bundle_signature}"
    end

    def codesign_certificate
      @codesign_certificate ||= begin
        cert_type = (distribution_mode ? 'Distribution' : 'Developer')
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

    def provisioned_devices
      @provisioned_devices ||= read_provisioned_profile_array('ProvisionedDevices')
    end

    def provisions_all_devices?
      @provisions_all_devices ||= !!read_provisioned_profile_boolean('ProvisionsAllDevices')
    end

    def seed_id
      @seed_id ||= begin
        seed_ids = read_provisioned_profile_array('ApplicationIdentifierPrefix')
        if seed_ids.size == 0
          App.fail "Can't find an application seed ID in the provisioning profile `#{provisioning_profile}'"
        elsif seed_ids.size > 1
          App.warn "Found #{seed_ids.size} seed IDs in the provisioning profile. Set the `seed_id' project setting. Will use the last one: `#{seed_ids.last}'"

    def print_crash_message
      $stderr.puts ''
      $stderr.puts '=' * 80
      $stderr.puts <<EOS
The application terminated. A crash report file may have been generated by the
system, use `rake crashlog' to open it. Use `rake debug=1' to restart the app
in the debugger.
EOS
      $stderr.puts '=' * 80
    end

    def clean_project
      paths = [self.build_dir]
      paths.concat(Dir.glob(self.resources_dirs.flatten.map{ |x| x + '/**/*.{nib,storyboardc,momd}' }))
      paths.each do |p|
        next if File.extname(p) == ".nib" && !File.exist?(p.sub(/\.nib$/, ".xib"))
        next if File.extname(p) == ".momd" && !File.exist?(p.sub(/\.momd$/, ".xcdatamodeld"))
        next if File.extname(p) == ".storyboardc" && !File.exist?(p.sub(/\.storyboardc$/, ".storyboard"))
        App.info 'Delete', relative_path(p)
        rm_rf p
        if File.exist?(p)
          # It can happen that because of file permissions a dir/file is not
          # actually removed, which can lead to confusing issues.
          App.fail "Failed to remove `#{relative_path(p)}'. Please remove this path manually."
        end
      end
    end

    def relative_path(path)
      if ENV['RM_TARGET_HOST_APP_PATH']
        Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(ENV['RM_TARGET_HOST_APP_PATH'])).to_s
      else
        path
      end
    end

    def rubymotion_env_value
      if spec_mode
        'test'
      else
        development? ? 'development' : 'release'
      end
    end
  end
end; end
