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
  class ExtensionTarget < Target
    def copy_products(platform)
      src_path = src_extension_path
      dest_path = destination_dir
      FileUtils.mkdir_p(File.join(@config.app_bundle(platform), 'PlugIns'))

      extension_path = destination_bundle_path

      if !File.exist?(extension_path) or File.mtime(src_path) > File.mtime(extension_path)
        App.info 'Copy', src_path
        FileUtils.cp_r(src_path, dest_path)
      end
    end

    def codesign(platform)
      extension_dir = destination_bundle_path

      # Create bundle/ResourceRules.plist.
      resource_rules_plist = File.join(extension_dir, 'ResourceRules.plist')

      # Codesign executable
      codesign_cmd = "CODESIGN_ALLOCATE=\"#{File.join(@config.platform_dir(platform), 'Developer/usr/bin/codesign_allocate')}\" /usr/bin/codesign"
      if File.mtime(@config.project_file) > File.mtime(extension_dir) \
          or !system("#{codesign_cmd} --verify \"#{extension_dir}\" >& /dev/null")
        App.info 'Codesign', extension_dir
        entitlements = File.join(extension_dir, "Entitlements.plist")
        sh "#{codesign_cmd} -f -s \"#{@config.codesign_certificate}\" --resource-rules=\"#{resource_rules_plist}\" --entitlements \"#{entitlements}\" \"#{extension_dir}\""
      end
    end

    def src_extension_path
      @src_extension_path ||= begin
        path = File.join(build_dir, '*.appex')
        Dir[path].sort_by{ |f| File.mtime(f) }.last
      end
    end

    # @return [String] The directory inside the application bundle where the
    #                  extension should be located in the final product.
    #
    def destination_dir
      File.join(@config.app_bundle(@platform), 'PlugIns')
    end

    # @return [String, nil] The path to the extension bundle inside the
    #         application bundle or `nil` if it has not been built yet.
    #
    def destination_bundle_path
      File.join(destination_dir, extension_name)
    end

    # @return [String, nil] The name of the extension or `nil` if it has not
    #         been built yet.
    #
    def extension_name
      File.basename(src_extension_path)
    end
  end
end;end
