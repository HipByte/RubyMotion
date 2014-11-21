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

require 'motion/project/template/ios/config'
require 'motion/project/template/ios-watch-host-config'

module Motion; module Project;
  class IOSWatchAppHostConfig < IOSConfig
    register :'ios-watch-host'

    def initialize(project_dir, build_mode)
      super
      @files = []
      @resources_dirs = []
      @name = ENV['watch_app_name'].sub(/ WatchKit Extension$/, '') << ' Watch App'
    end

    # TODO datadir should not depend on the template name
    def datadir(target=deployment_target)
      File.join(motiondir, 'data', 'ios', target)
    end

    # TODO datadir should not depend on the template name
    def supported_versions
      @supported_versions ||= Dir.glob(File.join(motiondir, 'data', 'ios', '*')).select{|path| File.directory?(path)}.map do |path|
        File.basename path
      end
    end

    def info_plist_data(platform)
      info_plist['CFBundleIdentifier'] = identifier + '.watchapp'
      super
    end

    def main_cpp_file_txt(_)
      main_txt = <<EOS
#import <UIKit/UIKit.h>
#include <dlfcn.h>

extern "C" {
int
main(int argc, char **argv)
{
  int retval = 0;
  if (dlopen("/System/Library/PrivateFrameworks/SockPuppetGizmo.framework/SockPuppetGizmo", 0x2) != NULL) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    retval = UIApplicationMain(argc, argv, @"SPApplication", @"SPApplicationDelegate");
    [pool release];
  } else {
    NSLog(@"Unable to load SockPuppetGizmo.framework");
    retval = 1;
  }
  return retval;
}
}
EOS
      main_txt
    end
  end
end; end
