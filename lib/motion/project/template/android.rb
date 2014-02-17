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
  # Compile Ruby files.
  java_dir = File.join(App.config.build_dir, 'java')
  FileUtils.mkdir_p(java_dir)
  ruby = File.join(App.config.motiondir, 'bin/ruby')
  init_func_n = 0
  ruby_objs = []
  bs_files = Dir.glob(File.join(App.config.versioned_datadir, 'BridgeSupport/*.bridgesupport'))
  ruby_bs_flags = bs_files.map { |x| "--uses-bs \"#{x}\"" }.join(' ')
  Dir.glob("./app/**/*.rb").each do |ruby_path|
    App.info 'Compile', ruby_path
    init_func = "InitRubyFile#{init_func_n += 1}"

    as_path = File.join(App.config.build_dir, App.config.arch, ruby_path + '.s')
    FileUtils.mkdir_p(File.dirname(as_path))
    sh "VM_PLATFORM=android VM_KERNEL_PATH=\"#{App.config.versioned_arch_datadir}/kernel-#{App.config.arch}.bc\" arch -i386 \"#{ruby}\" #{ruby_bs_flags} --emit-llvm \"#{as_path}\" #{init_func} \"#{java_dir}\" \"#{ruby_path}\""

    obj_path = File.join(App.config.build_dir, App.config.arch, ruby_path + '.o')
    sh "#{App.config.cc} #{App.config.asflags} -c \"#{as_path}\" -o \"#{obj_path}\""

    ruby_objs << [obj_path, init_func]
  end

  # Generate payload main file.
  payload_c_txt = <<EOS
// This file has been generated. Do not modify by hands.
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <jni.h>
#include <assert.h>
#include <android/log.h>
EOS
  ruby_objs.each do |_, init_func|
    payload_c_txt << "void #{init_func}(void *rcv, void *sel);\n" 
  end
  payload_c_txt << <<EOS
void rb_vm_register_method(jclass klass, const char *sel, bool class_method, const char *signature);
void rb_vm_register_native_methods(void);
bool rb_vm_init(const char *app_package, JNIEnv *env);
jint
JNI_OnLoad(JavaVM *vm, void *reserved)
{
    __android_log_write(ANDROID_LOG_INFO, "INFO", "loading payload");
    JNIEnv *env = NULL;
    if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) != JNI_OK) {
	return -1;
    }
    assert(env != NULL);
    rb_vm_init("#{App.config.package.gsub('.', '/')}", env);
EOS
  ruby_objs.each do |_, init_func|
    payload_c_txt << "    #{init_func}(NULL, NULL);\n"
  end
  payload_c_txt << <<EOS
    rb_vm_register_native_methods();
    __android_log_write(ANDROID_LOG_INFO, "INFO", "Loaded payload");
    return JNI_VERSION_1_6;
}
EOS
  payload_c = File.join(App.config.build_dir, 'jni/payload.c')
  mkdir_p File.dirname(payload_c)
  File.open(payload_c, 'w') { |io| io.write(payload_c_txt) }

  # Compile and link payload library.
  libs_abi_subpath = "lib/armeabi"
  libpayload_subpath = "#{libs_abi_subpath}/#{App.config.payload_library_name}"
  libpayload_path = "#{App.config.build_dir}/#{libpayload_subpath}" 
  payload_o = File.join(File.dirname(payload_c), 'payload.o')
  App.info 'Create', libpayload_path
  sh "#{App.config.cc} #{App.config.cflags} -c \"#{payload_c}\" -o \"#{payload_o}\""
  FileUtils.mkdir_p(File.dirname(libpayload_path))
  sh "#{App.config.cxx} #{App.config.ldflags} \"#{payload_o}\" #{ruby_objs.map { |o, _| "\"" + o + "\"" }.join(' ')} -o \"#{libpayload_path}\" #{App.config.ldlibs}"

  # Create a build/libs -> build/lib symlink (important for ndk-gdb).
  Dir.chdir(App.config.build_dir) { ln_s 'lib', 'libs' unless File.exist?('libs') }

  # Copy the gdb server.
  gdbserver_subpath = "#{libs_abi_subpath}/gdbserver"
  gdbserver_path = "#{App.config.build_dir}/#{gdbserver_subpath}" 
  App.info 'Create', gdbserver_path
  sh "/usr/bin/install -p #{App.config.ndk_path}/prebuilt/android-arm/gdbserver/gdbserver #{File.dirname(gdbserver_path)}"

  # Create the gdb config file.
  gdbconfig_path = "#{App.config.build_dir}/#{libs_abi_subpath}/gdb.setup"
  App.info 'Create', gdbconfig_path
  File.open(gdbconfig_path, 'w') do |io|
    io.puts <<EOS
set solib-search-path #{libs_abi_subpath}
EOS
  end

  # Compile java files.
  android_jar = "#{App.config.sdk_path}/platforms/android-#{App.config.api_version}/android.jar"
  vendored_jars = App.config.vendored_jars
  classes_dir = File.join(App.config.build_dir, 'classes')
  FileUtils.mkdir_p(classes_dir)
  class_path = [classes_dir, "#{App.config.sdk_path}/tools/support/annotations.jar", *vendored_jars].map { |x| "\"#{x}\"" }.join(':')
  rebuild_dex_classes = false
  Dir.glob(File.join(App.config.build_dir, 'java', '**', '*.java')).each do |java_path|
    paths = java_path.split('/')
    paths[paths.index('java')] = 'classes'
    paths[-1].sub!(/\.java$/, '.class')
    class_path = paths.join('/')
    if !File.exist?(class_path) or File.mtime(java_path) > File.mtime(class_path)
      App.info 'Compile', java_path
      sh "/usr/bin/javac -d \"#{classes_dir}\" -classpath #{class_path} -sourcepath \"#{java_dir}\" -target 1.5 -bootclasspath \"#{android_jar}\" -encoding UTF-8 -g -source 1.5 \"#{java_path}\""
      rebuild_dex_classes = true
    end
  end

  # Generate the dex file.
  dex_classes = File.join(App.config.build_dir, 'classes.dex')
  if !File.exist?(dex_classes) or rebuild_dex_classes
    App.info 'Create', dex_classes
    sh "\"#{App.config.build_tools_dir}/dx\" --dex --output \"#{dex_classes}\" \"#{classes_dir}\" \"#{App.config.sdk_path}/tools/support/annotations.jar\" #{vendored_jars.join(' ')}"
  end

  # Generate the Android manifest file.
  android_manifest = File.join(App.config.build_dir, 'AndroidManifest.xml')
  App.info 'Create', android_manifest
  File.open(android_manifest, 'w') do |io|
    io.print <<EOS
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="#{App.config.package}" android:versionCode="1" android:versionName="1.0">
	<uses-sdk android:minSdkVersion="#{App.config.api_version}"/>
	<application android:label="#{App.config.name}" android:debuggable="true">
        	<activity android:name="#{App.config.main_activity}" android:label="#{App.config.name}">
            		<intent-filter>
                		<action android:name="android.intent.action.MAIN" />
                		<category android:name="android.intent.category.LAUNCHER" />
            		</intent-filter>
        	</activity>
EOS
    (App.config.sub_activities.uniq - [App.config.main_activity]).each do |activity|
      io.print <<EOS
		<activity android:name="#{activity}" android:label="#{activity}" android:parentActivityName="#{App.config.main_activity}">
			<meta-data android:name="android.support.PARENT_ACTIVITY" android:value="#{App.config.main_activity}"/>
		</activity>
EOS
    end
    io.print <<EOS
    </application>
</manifest> 
EOS
  end

  # Generate the APK file.
  archive = App.config.apk_path
  if !File.exist?(archive) or File.mtime(dex_classes) > File.mtime(archive) or File.mtime(libpayload_path) > File.mtime(archive)
    App.info 'Create', archive
    resource_flags = App.config.resources_dirs.map { |x| '-S "' + x + '"' }.join(' ')
    sh "\"#{App.config.build_tools_dir}/aapt\" package -f -M \"#{android_manifest}\" #{resource_flags} -I \"#{android_jar}\" -F \"#{archive}\""
    Dir.chdir(App.config.build_dir) do
      sh "\"#{App.config.build_tools_dir}/aapt\" add -f \"../#{archive}\" \"#{File.basename(dex_classes)}\" > /dev/null"
      sh "\"#{App.config.build_tools_dir}/aapt\" add -f \"../#{archive}\" #{libpayload_subpath} > /dev/null"
      sh "\"#{App.config.build_tools_dir}/aapt\" add -f \"../#{archive}\" #{gdbserver_subpath} > /dev/null"
    end

    # Create the debug keystore if needed.
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

def adb_mode_flag(mode)
  case mode
    when :emulator
      '-e'
    when :device
      '-d'
    else
      raise
  end
end

def adb_path
  "#{App.config.sdk_path}/platform-tools/adb"
end

def install_apk(mode)
  App.info 'Install', App.config.apk_path
  sh "\"#{adb_path}\" #{adb_mode_flag(mode)} install -r \"#{App.config.apk_path}\""
end

def run_apk(mode)
  if ENV['debug']
    Dir.chdir(App.config.build_dir) do
      App.info 'Debug', App.config.apk_path
      sh "\"#{App.config.ndk_path}/ndk-gdb\" -e --adb=\"#{adb_path}\" --start"
    end
  else
    activity_path = "#{App.config.package}/.#{App.config.main_activity}"
    App.info 'Start', activity_path
    sh "\"#{adb_path}\" #{adb_mode_flag(mode)} shell am start -a android.intent.action.MAIN -n #{activity_path}"
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
    install_apk(:emulator)
  end

  desc "Start the app's main intent in the emulator"
  task :start => ['build', 'emulator:start_avd', 'emulator:install'] do
    run_apk(:emulator)
  end
end

namespace 'device' do
  desc "Install the app in the device"
  task :install do
    install_apk(:device)
  end

  desc "Start the app's main intent in the device"
  task :start do
    run_apk(:device)
  end
end

desc "Build the app then run it in the device"
task :device => ['build', 'device:install', 'device:start']

desc "Build the app then run it in the emulator"
task :default => 'emulator:start'
