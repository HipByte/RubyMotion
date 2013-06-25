# -*- coding: utf-8 -*-
#
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
      :api_level

    def initialize(project_dir, build_mode)
      super
      @avd_config = { :name => 'RubyMotion', :target => '1', :abi => 'armeabi-v7a' }
      @main_activity = '.Main'
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

    def api_level
      @api_level ||= begin
        levels = Dir.glob(sdk_path + '/platforms/android-*').map do |path|
          md = File.basename(path).match(/\d+$/)
          md ? md[0] : nil
        end.compact
        if levels.empty?
          App.fail "Given Android SDK does not support any API level (nothing relevant in `#{sdk_path}/platforms')"
        end
        levels.sort.max
      end
    end

    def apk_path
      File.join(build_dir, name + '.apk')
    end
  end
end; end
