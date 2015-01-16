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

require 'motion/project/target'

module Motion; module Project
  class FrameworkTarget < Target
    def copy_products(platform)
      src_path = framework_path
      dest_framework_dir = File.join(@config.app_bundle(platform), 'Frameworks')
      dest_path = File.join(dest_framework_dir, framework_name)

      if !File.exist?(dest_path) or File.mtime(src_path) > File.mtime(dest_path)
        App.info 'Copy', src_path
        FileUtils.mkdir_p(dest_framework_dir)
        FileUtils.cp_r(src_path, dest_framework_dir)
      end
    end

    def codesign(platform)
      # Create bundle/ResourceRules.plist.
      resource_rules_plist = File.join(@config.app_bundle(platform), 'Frameworks', framework_name, 'ResourceRules.plist')
      unless File.exist?(resource_rules_plist)
        App.info 'Create', resource_rules_plist
        File.open(resource_rules_plist, 'w') do |io|
          io.write(<<-PLIST)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>rules</key>
        <dict>
                <key>.*</key>
                <true/>
                <key>Info.plist</key>
                <dict>
                        <key>omit</key>
                        <true/>
                        <key>weight</key>
                        <real>10</real>
                </dict>
                <key>ResourceRules.plist</key>
                <dict>
                        <key>omit</key>
                        <true/>
                        <key>weight</key>
                        <real>100</real>
                </dict>
        </dict>
</dict>
</plist>
PLIST
        end
      end

      codesign_cmd = "CODESIGN_ALLOCATE=\"#{File.join(@config.platform_dir(platform), 'Developer/usr/bin/codesign_allocate')}\" /usr/bin/codesign"
      
      framework_path = File.join(@config.app_bundle(platform), 'Frameworks', framework_name)
      if File.mtime(@config.project_file) > File.mtime(framework_path) \
          or !system("#{codesign_cmd} --verify \"#{framework_path}\" >& /dev/null")
        App.info 'Codesign', framework_path
        sh "#{codesign_cmd} -f -s \"#{@config.codesign_certificate}\" --resource-rules=\"#{resource_rules_plist}\" \"#{framework_path}\""
      end
    end

    def framework_path
      @framework_path ||= begin
        path = File.join(build_dir, '*.framework')
        Dir[path].sort_by{ |f| File.mtime(f) }.last
      end
    end

    def framework_name
      File.basename(framework_path)
    end

    # Indicates whether to load the framework at runtime or not
    def load?
      @opts[:load]
    end

    # @return [Array<String>] A list of symbols that the framework requires the
    #         host application or extension to provide and should not strip.
    #
    def required_symbols
      executable_filename = File.basename(framework_path, '.framework')
      executable = File.join(framework_path, executable_filename)
      cmd = "/usr/bin/nm -ju '#{executable}' | /usr/bin/grep -E '^_(rb|vm)_'"
      puts cmd if App::VERBOSE
      `#{cmd}`.strip.split("\n")
    end
  end
end;end
