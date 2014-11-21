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

require 'motion/project/template/ios-extension-config'

module Motion; module Project;
  class IOSWatchExtensionConfig < IOSExtensionConfig
    register :'ios-extension'

    def info_plist_data(platform)
      info_plist['CFBundleIdentifier'] = identifier + '.watchkitextension'
      Motion::PropertyList.to_s({
        'MinimumOSVersion' => deployment_target,
        'CFBundleResourceSpecification' => 'ResourceRules.plist',
        'CFBundleSupportedPlatforms' => [deploy_platform],
        # TODO temp hack to get ints for Instruments, but strings for normal builds.
        'UIDeviceFamily' => device_family_ints.map { |x| ENV['__USE_DEVICE_INT__'] ? x.to_i : x.to_s },
        'DTXcode' => begin
          vers = xcode_version[0].gsub(/\./, '')
          if vers.length == 2
            '0' + vers + '0'
          else
            '0' + vers
          end
        end,
        'DTXcodeBuild' => xcode_version[1],
        'DTSDKName' => "#{platform.downcase}#{sdk_version}",
        'DTSDKBuild' => sdk_build_version(platform),
        'DTPlatformName' => platform.downcase,
        'DTCompiler' => 'com.apple.compilers.llvm.clang.1_0',
        'DTPlatformVersion' => sdk_version,
        'DTPlatformBuild' => sdk_build_version(platform),
      }.merge(generic_info_plist).merge(dt_info_plist).merge(info_plist)
       .merge({ 'CFBundlePackageType' => 'XPC!' }))
    end

    def manifest_plist_data
      return nil if manifest_assets.empty?
      Motion::PropertyList.to_s({
        'items' => [
          { 'assets' => manifest_assets,
            'metadata' => {
              'bundle-identifier' => identifier,
              'bundle-version' => @version,
              'kind' => 'software',
              'title' => @name
            } }
        ]
      })
    end

    def main_cpp_file_txt(spec_objs)
      main_txt = <<EOS
#import <UIKit/UIKit.h>
#include <objc/message.h>
#include <dlfcn.h>

extern "C" {
    void rb_define_global_const(const char *, void *);
    void rb_rb2oc_exc_handler(void);
    void rb_exit(int);
    void RubyMotionInit(int argc, char **argv);
EOS
      main_txt << <<EOS
}
EOS
      main_txt << <<EOS
int
main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retval = 0;
EOS
    if ENV['ARR_CYCLES_DISABLE']
      main_txt << <<EOS
    setenv("ARR_CYCLES_DISABLE", "1", true);
EOS
    end
    main_txt << <<EOS
    RubyMotionInit(argc, argv);
EOS
    main_txt << <<EOS
    dlopen("/System/Library/PrivateFrameworks/PlugInKit.framework/PlugInKit", 0x2);
    retval = ((int(*)(id, SEL, int, char**))objc_msgSend)(NSClassFromString(@"PKService"), @selector(_defaultRun:arguments:), argc, argv);
    rb_exit(retval);
    [pool release];
    return retval;
}
EOS
    end
  end
end; end
