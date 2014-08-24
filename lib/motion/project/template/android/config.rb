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

module Motion; module Project;
  class AndroidConfig < Config
    register :android

    variable :sdk_path, :ndk_path, :avd_config, :package, :main_activity,
      :sub_activities, :api_version, :arch, :assets_dirs, :icon,
      :logs_components, :version_code, :version_name, :permissions

    def initialize(project_dir, build_mode)
      super
      @avd_config = { :name => 'RubyMotion', :target => '1', :abi => 'armeabi-v7a' }
      @main_activity = 'MainActivity'
      @sub_activities = []
      @arch = 'armv5te'
      @assets_dirs = [File.join(project_dir, 'assets')]
      @vendored_projects = []
      @permissions = []
      @manifest_entries = {}
      @release_keystore_path = nil
      @release_keystore_alias = nil
      @version_code = '1'
      @version_name = '1.0'

      if path = ENV['RUBYMOTION_ANDROID_SDK']
        @sdk_path = File.expand_path(path)
      end
      if path = ENV['RUBYMOTION_ANDROID_NDK']
        @ndk_path = File.expand_path(path)
      end
    end

    def validate
      if !sdk_path or !File.exist?(sdk_path)
        App.fail "app.sdk_path should point to a valid Android SDK directory."
      end

      if !ndk_path or !File.exist?(ndk_path)
        App.fail "app.ndk_path should point to a valid Android NDK directory."
      end

      if !File.exist?("#{ndk_path}/platforms/android-#{api_version_ndk}")
        App.fail "It looks like your version of the NDK does not support API level #{api_version}. Switch to a lower API level or install a more recent NDK."
      end

      super
    end

    def zipalign_path
      @zipalign ||= begin
        ary = Dir.glob(File.join(sdk_path, 'build-tools/*/zipalign'))
        if ary.empty?
          path = File.join(sdk_path, 'tools/zipalign')
          unless File.exist?(path)
            App.fail "Can't locate `zipalign' tool. Make sure you properly installed the Android Build Tools package and try again."
          end
          path
        else
          ary.last
        end
      end
    end

    def package
      @package ||= 'com.yourcompany' + '.' + name.downcase.gsub(/\s/, '')
    end

    def package_path
      package.gsub('.', '/')
    end

    def api_version
      @api_version ||= begin
        versions = Dir.glob(sdk_path + '/platforms/android-*').map do |path|
          md = File.basename(path).match(/\d+$/)
          md ? md[0] : nil
        end.compact
        if versions.empty?
          App.fail "Given Android SDK does not support any API version (nothing relevant in `#{sdk_path}/platforms')"
        end
        vers = versions.map { |x| x.to_i }.max
        vers == 20 ? 'L' : vers.to_s
      end
    end

    def versionized_build_dir
      File.join(build_dir, build_mode_name + '-' + api_version)
    end

    def build_tools_dir
      @build_tools_dir ||= Dir.glob(sdk_path + '/build-tools/*').sort { |x, y| File.basename(x) <=> File.basename(y) }.max
    end

    def apk_path
      File.join(versionized_build_dir, name + '.apk')
    end

    def ndk_toolchain_bin_dir
      File.join(ndk_path, 'toolchains/llvm-3.3/prebuilt/darwin-x86_64/bin')
    end

    def cc
      File.join(ndk_toolchain_bin_dir, 'clang')
    end

    def cxx
      File.join(ndk_toolchain_bin_dir, 'clang++')
    end

    def asflags
      archflags = case arch
        when 'armv5te'
          "-march=armv5te"
        when 'armv7'
          "-march=armv7a -mfpu=vfpv3-d16"
        else
          raise "Invalid arch `#{arch}'"
      end
      "-no-canonical-prefixes -target #{arch}-none-linux-androideabi #{archflags} -mthumb -msoft-float -marm -gcc-toolchain \"#{ndk_path}/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64\""
    end

    def api_version_ndk
      @api_version_ndk ||=
        # NDK does not provide headers for versions of Android with no native
        # API changes (ex. 10 and 11 are the same as 9).
        case api_version
          when '6', '7'
            '5'
          when '10', '11'
            '9'
          else
            api_version
        end
    end

    def cflags
      archflags = case arch
        when 'armv5te'
          "-mtune=xscale"
      end
      "#{asflags} #{archflags} -MMD -MP -fpic -ffunction-sections -funwind-tables -fexceptions -fstack-protector -fno-rtti -fno-strict-aliasing -O0 -g3 -fno-omit-frame-pointer -DANDROID -I\"#{ndk_path}/platforms/android-#{api_version_ndk}/arch-arm/usr/include\" -Wformat -Werror=format-security"
    end

    def cxxflags
      "#{cflags} -I\"#{ndk_path}/sources/cxx-stl/stlport/stlport\""
    end

    def payload_library_filename
      "lib#{payload_library_name}.so"
    end

    def payload_library_name
      'payload'
    end

    def ldflags
      "-Wl,-soname,#{payload_library_filename} -shared --sysroot=\"#{ndk_path}/platforms/android-#{api_version_ndk}/arch-arm\" -lgcc  -gcc-toolchain \"#{ndk_path}/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64\" -no-canonical-prefixes -target #{arch}-none-linux-androideabi  -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now"
    end

    def versioned_datadir
      "#{motiondir}/data/android/#{api_version}"
    end

    def versioned_arch_datadir
      "#{versioned_datadir}/#{arch}"
    end

    def ldlibs
      # The order of the libraries matters here.
      "-L\"#{ndk_path}/platforms/android-#{api_version}/arch-arm/usr/lib\" -lstdc++ -lc -lm -llog -L\"#{versioned_arch_datadir}\" -lrubymotion-static -L#{ndk_path}/sources/cxx-stl/stlport/libs/armeabi -lstlport_static"
    end

    def armeabi_directory_name
      case arch
        when 'armv5te'
          'armeabi'
        when 'armv7'
          'armeabi-v7a'
        else
          raise "Invalid arch `#{arch}'"
      end 
    end

    def bin_exec(name)
      File.join(App.config.motiondir, 'bin', name)
    end

    attr_reader :vendored_projects

    def vendor_project(opt)
      jar = opt.delete(:jar)
      App.fail "Expected `:jar' key/value pair in `#{opt}'" unless jar
      res = opt.delete(:resources)
      manifest = opt.delete(:manifest)
      App.fail "Expected `:manifest' key/value pair when `:resources' is given" if res and !manifest
      App.fail "Expected `:resources' key/value pair when `:manifest' is given" if manifest and !res
      App.fail "Unused arguments: `#{opt}'" unless opt.empty?

      package = nil
      if manifest
        line = `/usr/bin/xmllint --xpath '/manifest/@package' \"#{manifest}\"`.strip
        App.fail "Given manifest `#{manifest}' does not have a `package' attribute in the top-level element" if $?.to_i != 0
        package = line.match(/package=\"(.+)\"$/)[1]
      end
      @vendored_projects << { :jar => jar, :resources => res, :manifest => manifest, :package => package }
    end

    def vendored_bs_files
      @vendored_bs_files ||= begin
        vendored_projects.map do |proj|
          jar_file = proj[:jar]
          bs_file = File.join(File.dirname(jar_file), File.basename(jar_file) + '.bridgesupport')
          if !File.exist?(bs_file) or File.mtime(jar_file) > File.mtime(bs_file)
            App.info 'Create', bs_file
            sh "#{bin_exec('android/gen_bridge_metadata')} \"#{jar_file}\" \"#{bs_file}\""
          end
          bs_file
        end
      end
    end

    def logs_components
      @logs_components ||= [package_path, 'AndroidRuntime', 'chromium', 'dalvikvm', 'Bundle'].map { |component| component + ':I' }
    end

    attr_reader :manifest_entries

    def manifest_entry(toplevel_element=nil, element, attributes)
      if toplevel_element
        App.fail "toplevel element must be either nil or `application'" unless toplevel_element == 'application'
      end
      elems = (@manifest_entries[toplevel_element] ||= [])
      elems << { :name => element, :attributes => attributes }
    end

    def manifest_xml_lines(toplevel_element)
      (@manifest_entries[toplevel_element] or []).map do |elem|
        name = elem[:name]
        attributes = elem[:attributes]
        attributes_line = attributes.to_a.map do |key, val|
          key = case key
            when :name
              'android:name'
            when :value
              'android:value'
            else
              key
          end
          "#{key}=\"#{val}\""
        end.join(' ')
        "<#{name} #{attributes_line}/>"
      end
    end

    attr_reader :release_keystore_path, :release_keystore_alias

    def release_keystore(path, alias_name)
      @release_keystore_path = path
      @release_keystore_alias = alias_name
    end

    def version(code, name)
      @version_code = code
      @version_name = name
    end
  end
end; end
