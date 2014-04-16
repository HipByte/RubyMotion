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

require 'motion/project/app'

App = Motion::Project::App
App.template = :android

require 'motion/project'
require 'motion/project/template/android/config'

desc "Create an application package file (.apk)"
task :build do
  # Compile Ruby files.
  ruby = File.join(App.config.motiondir, 'bin/ruby')
  init_func_n = 0
  ruby_objs = []
  bs_files = Dir.glob(File.join(App.config.versioned_datadir, 'BridgeSupport/*.bridgesupport'))
  ruby_bs_flags = bs_files.map { |x| "--uses-bs \"#{x}\"" }.join(' ')
  objs_build_dir = File.join(App.config.build_dir, 'obj', 'local', App.config.armeabi_directory_name)
  App.config.files.each do |ruby_path|
    App.info 'Compile', ruby_path
    init_func = "InitRubyFile#{init_func_n += 1}"

    bc_path = File.join(objs_build_dir, ruby_path + '.bc')
    FileUtils.mkdir_p(File.dirname(bc_path))
    sh "VM_PLATFORM=android VM_KERNEL_PATH=\"#{App.config.versioned_arch_datadir}/kernel-#{App.config.arch}.bc\" arch -i386 \"#{ruby}\" #{ruby_bs_flags} --emit-llvm \"#{bc_path}\" #{init_func} \"#{ruby_path}\""

    ruby_objs << [bc_path, init_func]
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
void rb_vm_register_native_methods(void);
bool rb_vm_init(const char *app_package, JNIEnv *env);
jint
JNI_OnLoad(JavaVM *vm, void *reserved)
{
    __android_log_write(ANDROID_LOG_DEBUG, "#{App.config.package_path}", "Loading payload");
    JNIEnv *env = NULL;
    if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) != JNI_OK) {
	return -1;
    }
    assert(env != NULL);
    rb_vm_init("#{App.config.package_path}", env);
EOS
  ruby_objs.each do |_, init_func|
    payload_c_txt << "    (*env)->PushLocalFrame(env, 32);\n"
    payload_c_txt << "    #{init_func}(NULL, NULL);\n"
    payload_c_txt << "    (*env)->PopLocalFrame(env, NULL);\n"
  end
  payload_c_txt << <<EOS
    rb_vm_register_native_methods();
    __android_log_write(ANDROID_LOG_DEBUG, "#{App.config.package_path}", "Loaded payload");
    return JNI_VERSION_1_6;
}
EOS
  payload_c = File.join(App.config.build_dir, 'jni/payload.c')
  mkdir_p File.dirname(payload_c)
  File.open(payload_c, 'w') { |io| io.write(payload_c_txt) }

  # Compile and link payload library.
  rm_rf "#{App.config.build_dir}/lib"
  libs_abi_subpath = "lib/#{App.config.armeabi_directory_name}"
  libpayload_subpath = "#{libs_abi_subpath}/#{App.config.payload_library_name}"
  libpayload_path = "#{App.config.build_dir}/#{libpayload_subpath}" 
  payload_o = File.join(File.dirname(payload_c), 'payload.o')
  App.info 'Create', libpayload_path
  sh "#{App.config.cc} #{App.config.cflags} -c \"#{payload_c}\" -o \"#{payload_o}\""
  FileUtils.mkdir_p(File.dirname(libpayload_path))
  sh "#{App.config.cxx} #{App.config.ldflags} \"#{payload_o}\" #{ruby_objs.map { |o, _| "\"" + o + "\"" }.join(' ')} -o \"#{libpayload_path}\" #{App.config.ldlibs}"

  # Create a build/libs -> build/lib symlink (important for ndk-gdb).
  Dir.chdir(App.config.build_dir) { ln_s 'lib', 'libs' unless File.exist?('libs') }

  # Create a build/jni/Android.mk file (important for ndk-gdb).
  File.open("#{App.config.build_dir}/jni/Android.mk", 'w') { |io| }

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

  # Create java files.
  java_classes = {}
  Dir.glob(objs_build_dir + '/**/*.map') do |map|
    txt = File.read(map)
    current_class = nil
    txt.each_line do |line|
      if md = line.match(/^([^\s]+)\s*:\s*([^\s]+)$/)
        current_class = java_classes[md[1]]
        if current_class
          if current_class[:super] != md[2]
            $stderr.puts "Class `#{md[1]}' already defined with a different super class (`#{current_class[:super]}')"
            exit 1
          end
        else
          current_class = {:super => md[2], :methods => []}
          java_classes[md[1]] = current_class
        end
      elsif md = line.match(/^\t(.+)$/)
        if current_class == nil
          $stderr.puts "Method definition outside class definition"
          exit 1
        end
        current_class[:methods] << md[1]
      else
        $stderr.puts "Ignoring line: #{line}"
      end
    end
  end
  java_dir = File.join(App.config.build_dir, 'java')
  rm_rf java_dir
  java_app_package_dir = File.join(java_dir, *App.config.package.split(/\./))
  mkdir_p java_app_package_dir
  java_classes.each do |name, klass|
    java_file = File.join(java_app_package_dir, name + '.java')
    App.info 'Create', java_file
    File.open(java_file, 'w') do |io|
      io.puts "// This file has been generated. Do not edit by hands."
      io.puts "package #{App.config.package};"
      io.puts "public class #{name} extends #{klass[:super]} {"
      klass[:methods].each do |method|
        io.puts "\t#{method};"
      end
      if name == App.config.main_activity
        io.puts "\tstatic {\n\t\tSystem.load(\"#{App.config.payload_library_name}\");\n\t}"
      end
      io.puts "}"
    end
  end

  # Compile java files.
  android_jar = "#{App.config.sdk_path}/platforms/android-#{App.config.api_version}/android.jar"
  vendored_jars = App.config.vendored_jars
  vendored_jars += [File.join(App.config.versioned_datadir, 'rubymotion.jar')]
  classes_dir = File.join(App.config.build_dir, 'classes')
  rm_rf classes_dir
  mkdir_p classes_dir
  class_path = [classes_dir, "#{App.config.sdk_path}/tools/support/annotations.jar", *vendored_jars].map { |x| "\"#{x}\"" }.join(':')
  Dir.glob(File.join(App.config.build_dir, 'java', '**', '*.java')).each do |java_path|
    paths = java_path.split('/')
    paths[paths.index('java')] = 'classes'
    paths[-1].sub!(/\.java$/, '.class')
    class_path = paths.join('/')
    if !File.exist?(class_path) or File.mtime(java_path) > File.mtime(class_path)
      App.info 'Compile', java_path
      sh "/usr/bin/javac -d \"#{classes_dir}\" -classpath #{class_path} -sourcepath \"#{java_dir}\" -target 1.5 -bootclasspath \"#{android_jar}\" -encoding UTF-8 -g -source 1.5 \"#{java_path}\""
    end
  end

  # Generate the dex file.
  dex_classes = File.join(App.config.build_dir, 'classes.dex')
  rm_rf dex_classes
  App.info 'Create', dex_classes
  sh "\"#{App.config.build_tools_dir}/dx\" --dex --output \"#{dex_classes}\" \"#{classes_dir}\" \"#{App.config.sdk_path}/tools/support/annotations.jar\" #{vendored_jars.join(' ')}"

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
      [File.basename(dex_classes), libpayload_subpath, gdbserver_subpath].each do |file|
        line = "\"#{App.config.build_tools_dir}/aapt\" add -f \"../#{archive}\" \"#{file}\""
        line << " > /dev/null" unless Rake.application.options.trace
        sh line
      end
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
  line = "\"#{adb_path}\" #{adb_mode_flag(mode)} install -r \"#{App.config.apk_path}\""
  line << " > /dev/null" unless Rake.application.options.trace
  sh line
end

def run_apk(mode)
  if ENV['debug']
    Dir.chdir(App.config.build_dir) do
      App.info 'Debug', App.config.apk_path
      sh "\"#{App.config.ndk_path}/ndk-gdb\" #{adb_mode_flag(mode)} --adb=\"#{adb_path}\" --start"
    end
  else
    # Clear log.
    sh "\"#{adb_path}\" #{adb_mode_flag(mode)} logcat -c"
    # Start main activity.
    activity_path = "#{App.config.package}/.#{App.config.main_activity}"
    App.info 'Start', activity_path
    line = "\"#{adb_path}\" #{adb_mode_flag(mode)} shell am start -a android.intent.action.MAIN -n #{activity_path}"
    line << " > /dev/null" unless Rake.application.options.trace
    sh line
    Signal.trap('INT') do
      # Kill the app on ^C.
      if `\"#{adb_path}\" -d shell ps`.include?(App.config.package)
        sh "\"#{adb_path}\" #{adb_mode_flag(mode)} shell am force-stop #{App.config.package}"
      end
      exit 0
    end
    # Show logs.
    sh "\"#{adb_path}\" #{adb_mode_flag(mode)} logcat -s #{App.config.package_path}:I"
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
