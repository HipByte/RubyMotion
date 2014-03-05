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
      :sub_activities, :api_version, :arch, :vendored_jars

    def initialize(project_dir, build_mode)
      super
      @avd_config = { :name => 'RubyMotion', :target => '1', :abi => 'armeabi-v7a' }
      @main_activity = '.Main'
      @sub_activities = []
      @arch = 'armv5te'
      @vendored_jars = []
    end

    def validate
      if !sdk_path or !File.exist?(sdk_path)
        App.fail "app.sdk_path should point to the Android SDK directory."
      end

      if !ndk_path or !File.exist?(ndk_path)
        App.fail "app.ndk_path should point to the Android NDK directory."
      end

      super
    end

    def package
      @package ||= 'com.yourcompany' + '.' + name.downcase.gsub(/\s/, '')
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
        versions.sort.max
      end
    end

    def build_tools_dir
      @build_tools_dir ||= Dir.glob(sdk_path + '/build-tools/android-*').sort { |x, y| File.basename(x) <=> File.basename(y) }.max
    end

    def apk_path
      File.join(build_dir, name + '.apk')
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
      "-no-canonical-prefixes -target #{arch}-none-linux-androideabi -march=#{arch} -msoft-float -mthumb -marm -gcc-toolchain \"#{ndk_path}/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64\" -Wa,--noexecstack"
    end

    def cflags
      "#{asflags} -MMD -MP -fpic -ffunction-sections -funwind-tables -fstack-protector -mtune=xscale -fno-rtti -fno-strict-aliasing -O0 -g -fno-omit-frame-pointer -DANDROID -I\"#{ndk_path}/platforms/android-#{api_version}/arch-arm/usr/include\" -Wformat -Werror=format-security"
    end

    def cxxflags
      "#{cflags} -I\"#{ndk_path}/sources/cxx-stl/stlport/stlport\""
    end

    def payload_library_name
      'libpayload.so'
    end

    def ldflags
      "-Wl,-soname,#{payload_library_name} -shared --sysroot=\"#{ndk_path}/platforms/android-#{api_version}/arch-arm\" -lgcc  -gcc-toolchain \"#{ndk_path}/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64\" -no-canonical-prefixes -target #{arch}-none-linux-androideabi  -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now"  
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
  end
end; end
