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

  class AndroidManifest < Hash

    attr_reader :name

    def initialize(name = 'manifest')
      @name = name
      @children = []
    end

    def add_child(name, properties = {}, &block)
      nested = AndroidManifest.new(name)
      nested.merge!(properties)
      block.call(nested) if block
      @children << nested
      nested
    end

    def child(name, &block)
      child = children(name).first
      block.call(child) if block
      child
    end

    def children(name)
      @children.select { |c| c.name == name }
    end

    def to_xml(depth = 0)
      str = "#{'  ' * depth}<#{@name} "

      str << map do |key, value|
        v = evaluate(value)
        # Some properties fail to compile if they are nil, so we clean them
        v.nil? ? nil : "#{key}=\"#{v}\""
      end.compact.join(' ')

      if @children.empty?
        str << " />\n"
      else
        str << " >\n"

        # children
        str << @children.map { |c| c.to_xml(depth + 1) }.join('')

        xml_lines_name = @name == "manifest" ? nil : @name
        str << App.config.manifest_xml_lines(xml_lines_name).map { |line| "#{'  ' * (depth + 1) }#{line}\n" }.join('')

        str << "#{'  ' * depth}</#{@name}>\n"
      end
      str
    end

    private

    def evaluate(value)
      if value.is_a? Proc
        value.call
      else
        value
      end
    end

  end

  class AndroidConfig < Config
    register :android

    variable :sdk_path, :ndk_path, :package, :main_activity, :sub_activities,
      :api_version, :target_api_version, :arch, :assets_dirs, :icon,
      :logs_components, :version_code, :version_name, :permissions, :features,
      :services, :application_class, :manifest, :theme

    def initialize(project_dir, build_mode)
      super
      @main_activity = 'MainActivity'
      @sub_activities = []
      @arch = 'armv5te'
      @assets_dirs = [File.join(project_dir, 'assets')]
      @vendored_projects = []
      @permissions = []
      @features = []
      @services = []
      @manifest_entries = {}
      @release_keystore_path = nil
      @release_keystore_alias = nil
      @version_code = '1'
      @version_name = '1.0'
      @application_class = nil
      @theme = "@android:style/Theme.Holo"

      @manifest = AndroidManifest.new
      construct_manifest

      if path = ENV['RUBYMOTION_ANDROID_SDK']
        @sdk_path = File.expand_path(path)
      end
      if path = ENV['RUBYMOTION_ANDROID_NDK']
        @ndk_path = File.expand_path(path)
      end
    end

    def construct_manifest
      manifest = @manifest

      manifest['xmlns:android'] = 'http://schemas.android.com/apk/res/android'
      manifest['package'] = -> { package }

      manifest['android:versionCode'] = -> { "#{version_code}" }
      manifest['android:versionName'] = -> { "#{version_name}" }

      manifest.add_child('uses-sdk') do |uses_sdk|
        uses_sdk['android:minSdkVersion'] = -> { "#{api_version}" }
        uses_sdk['android:targetSdkVersion'] = -> { "#{target_api_version}" }
      end

      manifest.add_child('application') do |application|
        application['android:label'] = -> { "#{name}" }
        application['android:debuggable'] = -> { "#{development? ? 'true' : 'false'}" }
        application['android:icon'] = -> { icon ? "@drawable/#{icon}" : nil }
        application['android:name'] = -> { application_class ? application_class : nil }
        application['android:theme'] = -> { "#{theme}" }
        application.add_child('activity') do |activity|
          activity['android:name'] = -> { main_activity }
          activity['android:label'] = -> { name }
          activity.add_child('intent-filter') do |filter|
            filter.add_child('action', 'android:name' => 'android.intent.action.MAIN' )
            filter.add_child('category', 'android:name' => 'android.intent.category.LAUNCHER' )
          end
        end
      end
    end

    def validate
      if !sdk_path or !File.exist?(sdk_path)
        App.fail "app.sdk_path should point to a valid Android SDK directory."
      end

      if !ndk_path or !File.exist?(ndk_path)
        App.fail "app.ndk_path should point to a valid Android NDK directory."
      end

      if api_version == nil or !File.exist?("#{sdk_path}//platforms/android-#{api_version}")
        App.fail "The Android SDK installed on your system does not support " + (api_version == nil ? "any API level" : "API level #{api_version}") + ". Run the `#{sdk_path}/tools/android' program to install missing API levels."
      end

      if !File.exist?("#{ndk_path}/platforms/android-#{api_version_ndk}")
        App.fail "The Android NDK installed on your system does not support API level #{api_version}. Switch to a lower API level or install a more recent NDK."
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

    def latest_api_version
      @latest_api_version ||= begin
        versions = Dir.glob(sdk_path + '/platforms/android-*').map do |path|
          md = File.basename(path).match(/\d+$/)
          md ? md[0] : nil
        end.compact
        return nil if versions.empty?
        numbers = versions.map { |x| x.to_i }
        vers = numbers.max
        if vers == 20
          if numbers.size > 1
            # Don't return 20 (L) by default, as it's not yet stable.
            numbers.delete(vers)
            vers = numbers.max
          else
            vers = 'L'
          end
        end
        vers.to_s
      end
    end

    def api_version
      @api_version ||= latest_api_version
    end

    def target_api_version
      @target_api_version ||= latest_api_version
    end

    def versionized_build_dir
      sep = spec_mode ? 'Testing' : build_mode_name
      File.join(build_dir, sep + '-' + api_version)
    end

    def build_tools_dir
      @build_tools_dir ||= Dir.glob(sdk_path + '/build-tools/*').sort { |x, y| File.basename(x) <=> File.basename(y) }.max
    end

    def apk_path
      File.join(versionized_build_dir, name + '.apk')
    end

    def ndk_toolchain_bin_dir
      @ndk_toolchain_bin_dir ||= begin
        paths = ['3.3', '3.4', '3.5'].map do |x|
          File.join(ndk_path, "toolchains/llvm-#{x}/prebuilt/darwin-x86_64/bin")
        end
        path = paths.find { |x| File.exist?(x) }
        App.fail "Can't locate a proper NDK toolchain (paths tried: #{paths.join(' ')})" unless path
        path
      end
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
      "-Wl,-soname,#{payload_library_filename} -shared --sysroot=\"#{ndk_path}/platforms/android-#{api_version_ndk}/arch-arm\" -lgcc  -gcc-toolchain \"#{ndk_path}/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64\" -no-canonical-prefixes -target #{arch}-none-linux-androideabi  -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -O0 -g3"
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
      File.join(motiondir, 'bin', name)
    end

    def kernel_path
      File.join(versioned_arch_datadir, "kernel-#{arch}.bc")
    end

    def clean_project
      super
      vendored_bs_files(false).each do |path|
        if File.exist?(path)
          App.info 'Delete', path
          FileUtils.rm_f path
        end
      end
    end

    attr_reader :vendored_projects

    def vendor_project(opt)
      jar = opt.delete(:jar)
      App.fail "Expected `:jar' key/value pair in `#{opt}'" unless jar
      res = opt.delete(:resources)
      manifest = opt.delete(:manifest)
      native = opt.delete(:native) || []
      App.fail "Expected `:manifest' key/value pair when `:resources' is given" if res and !manifest
      App.fail "Expected `:resources' key/value pair when `:manifest' is given" if manifest and !res
      App.fail "Unused arguments: `#{opt}'" unless opt.empty?
      native.each do |native_lib|
        App.fail "Expected '#{native_lib}' to target #{arch}, arm shared libraries are currently supported" unless native_lib =~ /\/#{arch}|armeabi\//
      end

      package = nil
      if manifest
        line = `/usr/bin/xmllint --xpath '/manifest/@package' \"#{manifest}\"`.strip
        App.fail "Given manifest `#{manifest}' does not have a `package' attribute in the top-level element" if $?.to_i != 0
        package = line.match(/package=\"(.+)\"$/)[1]
      end
      @vendored_projects << { :jar => jar, :resources => res, :manifest => manifest, :package => package, :native => native }
    end

    def vendored_bs_files(create=true)
      @vendored_bs_files ||= begin
        vendored_projects.map do |proj|
          jar_file = proj[:jar]
          bs_file = File.join(File.dirname(jar_file), File.basename(jar_file) + '.bridgesupport')
          if create and (!File.exist?(bs_file) or File.mtime(jar_file) > File.mtime(bs_file))
            App.info 'Create', bs_file
            sh "#{bin_exec('android/gen_bridge_metadata')} -o \"#{bs_file}\" \"#{jar_file}\""
          end
          bs_file
        end
      end
    end

    def logs_components
      @logs_components ||= begin
        ary = []
        ary << package_path + ':I'
        %w{AndroidRuntime chromium dalvikvm Bundle art}.each do |comp|
          ary << comp + ':E'
        end
        ary
      end
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
