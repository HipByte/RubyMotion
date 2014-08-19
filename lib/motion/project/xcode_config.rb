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

require 'motion/project/config'
require 'motion/util/code_sign'

module Motion; module Project;
  class XcodeConfig < Config
    variable :xcode_dir, :sdk_version, :deployment_target, :frameworks,
      :weak_frameworks, :embedded_frameworks, :external_frameworks, :framework_search_paths,
      :libs, :identifier, :codesign_certificate, :short_version, :entitlements, :delegate_class,
      :version

    def initialize(project_dir, build_mode)
      super
      @info_plist = {}
      @dependencies = {}
      @frameworks = []
      @weak_frameworks = []
      @embedded_frameworks = []
      @external_frameworks = []
      @framework_search_paths = []
      @libs = []
      @bundle_signature = '????'
      @short_version = nil
      @entitlements = {}
      @delegate_class = 'AppDelegate'
      @spec_mode = false
      @vendor_projects = []
      @version = '1.0'
    end

    def xcode_dir
      @xcode_version = nil
      @xcode_dir ||= begin
        xcode_dot_app_path = '/Applications/Xcode.app/Contents/Developer'

        # First, honor /usr/bin/xcode-select
        xcodeselect = '/usr/bin/xcode-select'
        if File.exist?(xcodeselect)
          path = `#{xcodeselect} -print-path`.strip
          if path.match(/^\/Developer\//) and File.exist?(xcode_dot_app_path)
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
      unescape_path(@xcode_dir)
    end

    def xcode_version
      @xcode_version ||= begin
        txt = `#{locate_binary('xcodebuild')} -version`
        vers = txt.scan(/Xcode\s(.+)/)[0][0]
        build = txt.scan(/(BuildVersion:|Build version)\s(.+)/)[0][1]
        [vers, build]
      end
    end

    def platforms; raise; end
    def local_platform; raise; end
    def deploy_platform; raise; end

    def validate
      # Xcode version
      App.fail "Xcode 4.x or greater is required" if xcode_version[0] < '4.0'

      # sdk_version
      platforms.each do |platform|
        sdk_path = File.join(platforms_dir, platform + '.platform',
            "Developer/SDKs/#{platform}#{sdk_version}.sdk")
        unless File.exist?(sdk_path)
          App.fail "Can't locate #{platform} SDK #{sdk_version} at `#{sdk_path}'" 
        end
      end

      # deployment_target
      if Util::Version.new(deployment_target) > Util::Version.new(sdk_version)
        App.fail "Deployment target `#{deployment_target}' must be equal or lesser than SDK version `#{sdk_version}'"
      end
      unless File.exist?(datadir)
        App.fail "iOS deployment target #{deployment_target} is not supported by this version of RubyMotion"
      end

      # embedded_frameworks
      %w{ embedded_frameworks external_frameworks }.each do |attr|
        value = send(attr)
        if !(value.is_a?(Array) and value.all? { |x| File.exist?(x) and File.extname(x) == '.framework' })
          App.fail "app.#{attr} should be an array of framework paths"
        end
      end

      super
    end

    def platforms_dir
      File.join(xcode_dir, 'Platforms')
    end

    def platform_dir(platform)
      File.join(platforms_dir, platform + '.platform')
    end

    def sdk_version
      @sdk_version ||= begin
        versions = Dir.glob(File.join(platforms_dir, "#{deploy_platform}.platform/Developer/SDKs/#{deploy_platform}*.sdk")).map do |path|
          File.basename(path).scan(/#{deploy_platform}(.*)\.sdk/)[0][0]
        end
        if versions.size == 0
          App.fail "Can't find an iOS SDK in `#{platforms_dir}'"
        end
        supported_vers = supported_sdk_versions(versions)
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
      path = File.join(platform_dir(platform), 'Developer/SDKs',
        platform + sdk_version + '.sdk')
      escape_path(path)
    end

    def frameworks_dependencies
      @frameworks_dependencies ||= begin
        # Compute the list of frameworks, including dependencies, that the project uses.
        deps = frameworks.dup.uniq
        slf = File.join(sdk(local_platform), 'System', 'Library', 'Frameworks')
        deps.each do |framework|
          framework_path = File.join(slf, framework + '.framework', framework)
          if File.exist?(framework_path)
            `#{locate_binary('otool')} -L \"#{framework_path}\"`.scan(/\t([^\s]+)\s\(/).each do |dep|
              # Only care about public, non-umbrella frameworks (for now).
              if md = dep[0].match(/^\/System\/Library\/Frameworks\/(.+)\.framework\/(Versions\/.\/)?(.+)$/) and md[1] == md[3]
                if File.exist?(File.join(datadir, 'BridgeSupport', md[1] + '.bridgesupport'))
                  deps << md[1]
                  deps.uniq!
                end
              end
            end
          end
        end

        if @framework_search_paths.empty?
          deps = deps.select { |dep| File.exist?(File.join(datadir, 'BridgeSupport', dep + '.bridgesupport')) }
        end
        deps
      end
    end

    def frameworks_stubs_objects(platform)
      stubs = []
      (frameworks_dependencies + weak_frameworks).uniq.each do |framework|
        stubs_obj = File.join(datadir, platform, "#{framework}_stubs.o")
        stubs << stubs_obj if File.exist?(stubs_obj)
      end
      stubs
    end

    def bridgesupport_files
      @bridgesupport_files ||= begin
        bs_files = []
        deps = ['RubyMotion'] + (frameworks_dependencies + weak_frameworks).uniq
        deps << 'UIAutomation' if spec_mode
        deps.each do |framework|
          supported_versions.each do |ver|
            next if Util::Version.new(ver) < Util::Version.new(deployment_target) || Util::Version.new(sdk_version) < Util::Version.new(ver)
            bs_path = File.join(datadir(ver), 'BridgeSupport', framework + '.bridgesupport')
            if File.exist?(bs_path)
              bs_files << bs_path
            end
          end
        end
        bs_files
      end
    end

    def default_archs
      h = {}
      platforms.each do |platform|
        h[platform] = Dir.glob(File.join(datadir, platform, '*.bc')).map do |path|
          path.scan(/kernel-(.+).bc$/)[0][0]
        end
      end
      h
    end

    def archs
      @archs ||= default_archs
    end

    def arch_flags(platform)
      archs[platform].map { |x| "-arch #{x}" }.join(' ')
    end

    def common_flags(platform)
      "#{arch_flags(platform)} -isysroot \"#{unescape_path(sdk(platform))}\" -F#{sdk(platform)}/System/Library/Frameworks"
    end

    def cflags(platform, cplusplus)
      optz_level = development? ? '-O0' : '-O3'
      "#{common_flags(platform)} #{optz_level} -fexceptions -fblocks" + (cplusplus ? '' : ' -std=c99') + (xcode_version[0] < '5.0' ? '' : ' -fmodules')
    end

    def ldflags(platform)
      common_flags(platform) + ' -Wl,-no_pie'
    end

    def bundle_name
      @name + (spec_mode ? '_spec' : '')
    end

    def versionized_build_dir(platform)
      File.join(build_dir, platform + '-' + deployment_target + '-' + build_mode_name)
    end

    def app_bundle_dsym(platform)
      File.join(versionized_build_dir(platform), bundle_name + '.dSYM')
    end

    def archive_extension
      raise "not implemented"
    end

    def archive
      File.join(versionized_build_dir(deploy_platform), bundle_name + archive_extension)
    end

    def identifier
      @identifier ||= "com.yourcompany.#{@name.gsub(/\s/, '')}"
      spec_mode ? @identifier + '_spec' : @identifier
    end

    def info_plist
      @info_plist
    end

    def dt_info_plist
      {}
    end

    def generic_info_plist
      {
        'BuildMachineOSBuild' => `sw_vers -buildVersion`.strip,
        'CFBundleDevelopmentRegion' => 'en',
        'CFBundleName' => @name,
        'CFBundleDisplayName' => @name,
        'CFBundleIdentifier' => identifier,
        'CFBundleExecutable' => @name, 
        'CFBundleInfoDictionaryVersion' => '6.0',
        'CFBundlePackageType' => 'APPL',
        'CFBundleShortVersionString' => (@short_version || @version),
        'CFBundleSignature' => @bundle_signature,
        'CFBundleVersion' => @version
      }
    end

    # TODO
    # * Add env vars from user.
    # * Add optional Instruments template to use.
    def profiler_config_plist(platform, args, template, builtin_templates, set_build_env = true)
      working_dir = File.expand_path(versionized_build_dir(platform))
      optional_data = {}

      if template
        template_path = nil
        if File.exist?(template)
          template_path = template
        elsif !builtin_templates.grep(/#{template}/i).empty?
          template = template.downcase
          template_path = profiler_known_templates.find do |path|
            File.basename(path, File.extname(path)).downcase == template
          end
        else
          App.fail("Invalid Instruments template path or name.")
        end
        optional_data['XrayTemplatePath'] = template_path
      end

      env = ENV.to_hash
      if set_build_env
        env.merge!({
          'DYLD_FRAMEWORK_PATH' => working_dir,
          'DYLD_LIBRARY_PATH' => working_dir,
          '__XCODE_BUILT_PRODUCTS_DIR_PATHS' => working_dir,
          '__XPC_DYLD_FRAMEWORK_PATH' => working_dir,
          '__XPC_DYLD_LIBRARY_PATH' => working_dir,
        })
      end

      {
        'CFBundleIdentifier' => identifier,
        'absolutePathOfLaunchable' => File.expand_path(app_bundle_executable(platform)),
        'argumentEntries' => (args or ''),
        'workingDirectory' => working_dir,
        'workspacePath' => '', # Normally: /path/to/Project.xcodeproj/project.xcworkspace
        'environmentEntries' => env,
        'optionalData' => {
          'launchOptions' => {
            'architectureType' => 1,
          },
        }.merge(optional_data),
      }
    end

    def profiler_known_templates
      # Get a list of just the templates (ignoring devices)
      list = `#{locate_binary('instruments')} -s 2>&1`.strip.split("\n")
      start = list.index('Known Templates:') + 1
      list = list[start..-1]
      # Only interested in the template (file base) names
      list.map { |line| line.sub(/^\s*"/, '').sub(/",*$/, '') }
    end

    def profiler_config_device_identifier(device_name, target)
      if xcode_version[0] >= '6.0'
        re = /#{device_name} \(#{target} Simulator\) \[(.+)\]/
        `#{locate_binary('instruments')} -s 2>&1`.strip.split("\n").each { |line|
          if m = re.match(line)
            return m[1]
          end
        }
      else
        App.config.sdk('iPhoneSimulator')
      end
    end

    def pkginfo_data
      "AAPL#{@bundle_signature}"
    end

    def codesign_certificate(platform)
      @codesign_certificate ||= begin
        type = (distribution_mode ? 'Distribution' : 'Developer')
        certs = Util::CodeSign.identity_names(release?)
        certs = certs.grep(/#{platform} #{type}/)
        if certs.size == 0
          App.fail "Cannot find any #{platform} #{type} certificate in the" \
                   "keychain"
        elsif certs.size > 1
          App.warn "Found #{certs.size} #{platform} #{type} certificates in " \
                   "the keychain. Set the `codesign_certificate' project " \
                   "setting to explicitely use one of (defaults to the " \
                   "first): #{certs.join(', ')}"
        end
        certs.first
      end
    end

    def gen_bridge_metadata(platform, headers, bs_file, c_flags, exceptions=[])
      sdk_path = self.sdk(local_platform)
      includes = ['-I.'] + headers.map { |header| "-I'#{File.dirname(header)}'" }.uniq
      exceptions = exceptions.map { |x| "\"#{x}\"" }.join(' ')
      c_flags = "#{c_flags} -isysroot '#{sdk_path}' #{bridgesupport_cflags} #{includes.join(' ')}"
      sh "RUBYOPT='' '#{File.join(bindir, 'gen_bridge_metadata')}' #{bridgesupport_flags} --cflags \"#{c_flags}\" #{headers.map { |x| "'#{x}'" }.join(' ')} -o '#{bs_file}' #{ "-e #{exceptions}" if exceptions.length != 0}"
    end

    def define_global_env_txt
      rubymotion_env =
        if spec_mode
          'test'
        else
          development? ? 'development' : 'release'
        end
      "rb_define_global_const(\"RUBYMOTION_ENV\", @\"#{rubymotion_env}\");\nrb_define_global_const(\"RUBYMOTION_VERSION\", @\"#{Motion::Version}\");\n"
    end

    def spritekit_texture_atlas_compiler
      path = File.join(xcode_dir, 'usr/bin/TextureAtlas')
      File.exist?(path) ? path : nil
    end

    def assets_bundles
      xcassets_bundles = []
      resources_dirs.each do |dir|
        if File.exist?(dir)
          xcassets_bundles.concat(Dir.glob(File.join(dir, '*.xcassets')))
        end
      end
      xcassets_bundles
    end

    def app_icons_asset_bundle
      app_icons_asset_bundles = assets_bundles.map { |b| Dir.glob(File.join(b, '*.appiconset')) }.flatten
      if app_icons_asset_bundles.size > 1
        App.warn "Found #{app_icons_asset_bundles.size} app icon sets across all " \
                 "xcasset bundles. Only the first one (alphabetically) " \
                 "will be used."
      end
      app_icons_asset_bundles.sort.first
    end

    def app_icon_name_from_asset_bundle
      File.basename(app_icons_asset_bundle, '.appiconset')
    end

    attr_reader :vendor_projects

    def vendor_project(path, type, opts={})
      opts[:force_load] = true unless opts[:force_load] == false
      @vendor_projects << Motion::Project::Vendor.new(path, type, self, opts)
    end

    def unvendor_project(path)
      @vendor_projects.delete_if { |x| x.path == path }
    end

    def clean_project
      super
      @vendor_projects.each { |vendor| vendor.clean }
    end
  end
end; end
