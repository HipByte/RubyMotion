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

require 'motion/project/builder'

module Motion; module Project
  class Builder
    def archive(config)
      # Create .pkg archive.
      app_bundle = config.app_bundle_raw('MacOSX')
      archive = config.archive
      if !File.exist?(archive) or File.mtime(app_bundle) > File.mtime(archive)
        App.info 'Create', archive
        sh "/usr/bin/productbuild --quiet --component \"#{app_bundle}\" /Applications \"#{archive}\""
      end
    end

    def codesign(config, platform)
      app_bundle = config.app_bundle_raw('MacOSX')
      entitlements = File.join(config.versionized_build_dir(platform), "Entitlements.plist")
      if File.mtime(config.project_file) > File.mtime(app_bundle) \
          or !system("/usr/bin/codesign --verify \"#{app_bundle}\" >& /dev/null")
        App.info 'Codesign', app_bundle
        File.open(entitlements, 'w') { |io| io.write(config.entitlements_data) }
        sh "/usr/bin/codesign --force --sign \"#{config.codesign_certificate}\" --entitlements \"#{entitlements}\" \"#{app_bundle}\""
      end
    end
  end
end; end
