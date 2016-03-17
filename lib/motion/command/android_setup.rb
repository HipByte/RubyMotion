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

module Motion; class Command
  class AndroidSetup < Command
    DefaultDirectory = File.join(File.expand_path("~"), '.rubymotion-android')
    DefaultSDKVersion = '24.4.1'
    DefaultNDKVersion = 'r10e'
    DefaultAPIVersion = '23'

    DL_GOOGLE = "https://dl.google.com/android"

    # use `tools/android list sdk --extended --all`
    # to get a list of available packages
    def sdk_packages
      [
        ["platform-tools", 'platform-tools'],
        ["build-tools-23.0.1", 'build-tools/23.0.1'],
        ["android-#{@api_version}", "platforms/android-#{@api_version}"],
        ["addon-google_apis-google-#{@api_version}", "add-ons/addon-google_apis-google-#{@api_version}"],
        ["sys-img-armeabi-v7a-addon-google_apis-google-#{@api_version}", "system-images/android-#{@api_version}/google_apis/armeabi-v7a"],
        ["extra-android-support", 'extras/android/support']
      ]
    end

    self.summary = 'Setup the Android environment.'
    self.description = 'Setup the Android environment (SDK and NDK).'

    def initialize(argv)
      @directory = File.expand_path(argv.option('directory') || DefaultDirectory)
      @sdk_version = argv.option('sdk_version') || DefaultSDKVersion
      @ndk_version = argv.option('ndk_version') || DefaultNDKVersion
      @api_version = argv.option('api_version') || DefaultAPIVersion
      @force = argv.flag?('force', false)
      @ndk_directory = File.join(@directory, 'ndk')
      @sdk_directory = File.join(@directory, 'sdk')
      @tmp_directory = File.join(@directory, 'tmp')
      super
    end

    def self.options
      [
        ['--directory=[PATH]', "The android install directory (default: #{DefaultDirectory})."],
        ['--sdk_version=[VERSION]', "The android SDK version (default: #{DefaultSDKVersion})."],
        ['--ndk_version=[VERSION]', "The android NDK version (default: #{DefaultNDKVersion})."],
        ['--api_version=[VERSION]', "The android API version (default: #{DefaultAPIVersion})."],
        ['--force', "Force the SDK and NDK re-installation."]
      ].concat(super)
    end

    def run
      check_java
      create_directory_structure
      setup_sdk
      setup_ndk
      check_env_variables
      open_gui
      FileUtils.rm_rf @tmp_directory
    end

    protected

    def open_gui
      system(android_executable)
    end

    def android_executable
      File.join(@sdk_directory, 'tools', 'android')
    end

    def setup_ndk
      if !File.exist?(@ndk_directory) || @ndk_version != current_ndk_version || @force
        puts("Installing NDK : version #{@ndk_version}")
        ndk_url = File.join(DL_GOOGLE, 'ndk', "android-ndk-#{@ndk_version}-darwin-x86_64.bin")
        ndk_bin = File.join(@tmp_directory, 'ndk.bin')
        download(ndk_url, ndk_bin)
        system('/bin/chmod', '+x', ndk_bin)
        Dir.chdir(@tmp_directory) { system(ndk_bin) }
        FileUtils.rm_rf(@ndk_directory)
        FileUtils.mv(File.join(@tmp_directory, "android-ndk-#{@ndk_version}"), @ndk_directory)
      else
        puts("Installed NDK is up-to-date.")
      end
    end

    def current_ndk_version
      File.read(File.join(@ndk_directory, 'RELEASE.TXT')).strip.split(' ')[0]
    end

    def setup_sdk
      if !File.exist?(android_executable) or @force
        puts("Installing SDK : version #{@sdk_version}")
        sdk_url = File.join(DL_GOOGLE, "android-sdk_r#{@sdk_version}-macosx.zip")
        zipped_sdk = File.join(@tmp_directory, "sdk.zip")
        download(sdk_url, zipped_sdk)
        extracted_sdk = File.join(@tmp_directory, 'sdk')
        system("/usr/bin/unzip -q -a \"#{zipped_sdk}\" -d \"#{extracted_sdk}\"")
        FileUtils.rm_rf @sdk_directory
        FileUtils.mv(File.join(extracted_sdk, 'android-sdk-macosx'), @sdk_directory)
      end

      packages_list = sdk_packages.map do |name, dir|
        name if !dir or @force or !File.exist?(File.join(@sdk_directory, dir))
      end.compact
      if packages_list.empty?
         puts "Installed SDK is up-to-date."
      else
         puts "Updating SDK..."
        system("\"#{android_executable}\" update sdk --all --no-ui --filter #{packages_list.join(',')}")
      end
    end

    def create_directory_structure
      FileUtils.mkdir_p(@tmp_directory)
    end

    def check_java
      unless File.exist?('/usr/bin/java')
        die("[error] Couldn't find Java, please make sure you have Java installed (we recommend version 1.6).")
      end
    end

    def check_env_variables
      if ENV['RUBYMOTION_ANDROID_SDK'] != @sdk_directory
        $stderr.puts("[error] RUBYMOTION_ANDROID_SDK is incorrect, should be #{@sdk_directory}")
        $stderr.puts("add `export RUBYMOTION_ANDROID_SDK=#{@sdk_directory}` to your ~/.profile")
      end
      if ENV['RUBYMOTION_ANDROID_NDK'] != @ndk_directory
        $stderr.puts("[error] RUBYMOTION_ANDROID_NDK is incorrect, should be #{@ndk_directory}")
        $stderr.puts("add `export RUBYMOTION_ANDROID_NDK=#{@ndk_directory}` to your ~/.profile")
      end
    end

    def curl(cmd)
      resp = `/usr/bin/curl --connect-timeout 60 #{cmd}`
      if $?.exitstatus != 0
        die("Error when connecting to the server. Check your Internet connection and try again.")
      end
      resp
    end

    def download(url, dest)
      axel_path = `/usr/bin/which axel`
      if $?.success?
        unless system("#{axel_path.strip} -n 10 -a -o '#{dest}' '#{url}'")
          die("Error when connecting to the server. Check your Internet connection and try again.")
        end
      else
        curl("-# '#{url}' -o '#{dest}'")
      end
    end
  end
end; end
