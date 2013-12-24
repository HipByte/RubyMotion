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

require 'motion/project/app'

App = Motion::Project::App
App.template = :android

require 'motion/project'
require 'motion/project/template/android/config'

desc "Create an application package file (.apk)"
task :build do
  libpayload_subpath = "lib/armeabi/libpayload.so"

  # XXX
  FileUtils.mkdir_p("#{App.config.build_dir}/#{File.dirname(libpayload_subpath)}")
  sh "#{App.config.ndk_path}/toolchains/arm-linux-androideabi-4.6/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-gcc -MMD -MP -fpic -ffunction-sections -funwind-tables -fstack-protector -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__ -no-canonical-prefixes -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -g -DNDEBUG -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -O0 -UNDEBUG -marm -fno-omit-frame-pointer -Ijni -DANDROID  -Wa,--noexecstack -I\"#{App.config.ndk_path}/platforms/android-#{App.config.api_level}/arch-arm/usr/include\" -c #{App.config.build_dir}/payload.c -o #{App.config.build_dir}/payload.o"
  sh "#{App.config.ndk_path}/toolchains/arm-linux-androideabi-4.6/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-g++ -Wl,-soname,libpayload.so -shared --sysroot=\"#{App.config.ndk_path}/platforms/android-#{App.config.api_level}/arch-arm\" #{App.config.build_dir}/payload.o -no-canonical-prefixes  -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now  -lc -lm -llog -o #{App.config.build_dir}/#{libpayload_subpath} -L#{File.join(App.config.motiondir, 'data', 'android', App.config.api_level, 'arm')} -lrubymotion-static -L#{App.config.ndk_path}/sources/cxx-stl/stlport/libs/armeabi -lstlport_static -g"
  # XXX

  classes_dir = File.join(App.config.build_dir, 'classes')
  java_dir = File.join(App.config.build_dir, 'java')
  FileUtils.mkdir_p(classes_dir)
 
  rebuild_dex_classes = false
  Dir.glob(File.join(App.config.build_dir, 'java', '**', '*.java')).each do |java_path|
    paths = java_path.split('/')
    paths[paths.index('java')] = 'classes'
    paths[-1].sub!(/\.java$/, '.class')
    class_path = paths.join('/')
    if !File.exist?(class_path) or File.mtime(java_path) > File.mtime(class_path)
      App.info 'Compile', java_path
      sh "/usr/bin/javac -d \"#{classes_dir}\" -classpath \"#{classes_dir}:#{App.config.sdk_path}/tools/support/annotations.jar\" -sourcepath \"#{java_dir}\" -target 1.5 -bootclasspath \"#{App.config.sdk_path}/platforms/android-#{App.config.api_level}/android.jar\" -encoding UTF-8 -g -source 1.5 \"#{java_path}\""
      rebuild_dex_classes = true
    end
  end

  dex_classes = File.join(App.config.build_dir, 'classes.dex')
  if !File.exist?(dex_classes) or rebuild_dex_classes
    App.info 'Create', dex_classes
    sh "\"#{App.config.build_tools_dir}/dx\" --dex --output \"#{dex_classes}\" \"#{classes_dir}\" \"#{App.config.sdk_path}/tools/support/annotations.jar\""
  end

  android_manifest = File.join(App.config.build_dir, 'AndroidManifest.xml')
  File.open(android_manifest, 'w') do |io|
    io.print <<EOS
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="#{App.config.package}"
      android:versionCode="1"
      android:versionName="1.0">
    <uses-sdk android:minSdkVersion="3" />
    <application android:label="#{App.config.name}"
                 android:debuggable="true">
        <activity android:name="#{App.config.main_activity}"
                  android:label="#{App.config.name}">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest> 
EOS
  end

  archive = App.config.apk_path
  if !File.exist?(archive) or File.mtime(dex_classes) > File.mtime(archive) or File.mtime(File.join(App.config.build_dir, libpayload_subpath)) > File.mtime(archive)
    App.info 'Create', archive
    resource_flags = App.config.resources_dirs.map { |x| '-S "' + x + '"' }.join(' ')
    sh "\"#{App.config.build_tools_dir}/aapt\" package -f -M \"#{android_manifest}\" #{resource_flags} -I \"#{App.config.sdk_path}/platforms/android-#{App.config.api_level}/android.jar\" -F \"#{archive}\""
    Dir.chdir(App.config.build_dir) do
      sh "\"#{App.config.build_tools_dir}/aapt\" add -f \"../#{archive}\" \"#{File.basename(dex_classes)}\""
      sh "\"#{App.config.build_tools_dir}/aapt\" add -f \"../#{archive}\" #{libpayload_subpath}"
    end

    debug_keystore = File.expand_path('~/.android/debug.keystore')
    unless File.exist?(debug_keystore)
      App.info 'Create', debug_keystore
      sh "/usr/bin/keytool -genkeypair -alias androiddebugkey -keypass android -keystore \"#{debug_keystore}\" -storepass android -dname \"CN=Android Debug,O=Android,C=US\" -validity 9999"
    end

    App.info 'Sign', archive
    sh "/usr/bin/jarsigner -storepass android -keystore \"#{debug_keystore}\" \"#{archive}\" androiddebugkey"

    App.info 'Align', archive
    sh "\"#{App.config.sdk_path}/tools/zipalign\" -f 4 \"#{archive}\" \"#{archive}-aligned\""
    sh "/bin/mv \"#{archive}-aligned\" \"#{archive}\""
  end
end

namespace 'emulator' do
  desc "Create the Android Virtual Device for the emulator"
  task :create_avd do
    all_targets = `\"#{App.config.sdk_path}/tools/android\" list avd --compact`.split(/\n/)
    if !all_targets.include?(App.config.avd_config[:name])
      sh "/bin/echo -n \"no\" | \"#{App.config.sdk_path}/tools/android\" create avd --name \"#{App.config.avd_config[:name]}\" --target \"#{App.config.avd_config[:target]}\" --abi \"#{App.config.avd_config[:abi]}\" --snapshot"
    end
  end

  desc "Start the emulator in the background"
  task :start_avd do
    unless `/bin/ps -a`.split(/\n/).any? { |x| x.include?('emulator64-arm') and x.include?('RubyMotion') }
      Rake::Task["emulator:create_avd"].invoke
      sh "\"#{App.config.sdk_path}/tools/emulator\" -avd \"#{App.config.avd_config[:name]}\" &"
      sh "\"#{App.config.sdk_path}/platform-tools/adb\" -e wait-for-device"
    end
  end

  desc "Install the app in the emulator"
  task :install do
    App.info 'Install', App.config.apk_path
    sh "\"#{App.config.sdk_path}/platform-tools/adb\" -e install -r \"#{App.config.apk_path}\""
  end

  desc "Start the app's main intent in the emulator"
  task :start => ['build', 'emulator:start_avd', 'emulator:install'] do
    activity_path = "#{App.config.package}/.#{App.config.main_activity}"
    App.info 'Start', activity_path
    sh "\"#{App.config.sdk_path}/platform-tools/adb\" -e shell am start -a android.intent.action.MAIN -n #{activity_path}"
  end
end

namespace 'device' do
  desc "Install the app in the device"
  task :install do
    App.info 'Install', App.config.apk_path
    sh "\"#{App.config.sdk_path}/platform-tools/adb\" -d install -r \"#{App.config.apk_path}\""
  end

  desc "Start the app's main intent in the device"
  task :start do
    activity_path = "#{App.config.package}/.#{App.config.main_activity}"
    App.info 'Start', activity_path
    sh "\"#{App.config.sdk_path}/platform-tools/adb\" -d shell am start -a android.intent.action.MAIN -n #{activity_path}"
  end
end

desc "Build the app then run it in the device"
task :device => ['build', 'device:install', 'device:start']

desc "Build the app then run it in the emulator"
task :default => 'emulator:start'
