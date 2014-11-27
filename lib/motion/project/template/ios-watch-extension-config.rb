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
      super
    end

    # @return [String] The name of the application.
    #
    def watch_app_name
      bundle_name.sub(" WatchKit Extension", '') + " Watch App"
    end

    # @return [String] The application bundle filename.
    #
    def watch_app_bundle_name
      "#{watch_app_name}.app"
    end

    # @param [String] platform
    #        The platform identifier that's being build for, such as
    #        `iPhoneSimulator` or `iPhoneOS`.
    #
    # @return [String] The path to the application bundle in this extension's
    #                  build directory.
    #
    def watch_app_bundle(platform)
      File.join(app_bundle(platform), watch_app_bundle_name)
    end

    # @return [String] The path to the application bundle inside the host
    #                  application in its build directory.
    #
    def embedded_watch_app_bundle
      File.join(ENV['RM_TARGET_DESTINATION_BUNDLE_PATH'], watch_app_bundle_name)
    end

    # @return [String] The path to the application executable inside the host
    #                  application in its build directory.
    #
    def embedded_watch_app_executable
      File.join(embedded_watch_app_bundle, watch_app_name)
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
