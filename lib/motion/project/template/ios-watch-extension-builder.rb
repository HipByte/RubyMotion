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

require 'motion/project/template/ios-extension-builder'

module Motion; module Project
  class Builder
    def build_watch_app(config, platform, opts)
      watch_app_bundle_path = config.watch_app_bundle(platform)

      # Copy watch app binary
      FileUtils.mkdir_p watch_app_bundle_path
      sh "/usr/bin/ditto -rsrc \"#{File.join(config.sdk(platform), "/Library/Application\ Support/SP/SP.app/SP")}\" \"#{watch_app_bundle_path}/#{config.watch_app_name}\""

      # Compile storyboard
      sh "/usr/bin/ibtool --errors --warnings --notices --module #{config.bundle_name.gsub(" ", "_")} --minimum-deployment-target #{config.sdk_version} --output-partial-info-plist /tmp/Interface-SBPartialInfo.plist --auto-activate-custom-fonts --output-format human-readable-text --compilation-directory \"#{watch_app_bundle_path}\" watch_app/Interface.storyboard"
    end

    def build_watch_extension(config, platform, opts)
      build_extension(config, platform, opts)
      build_watch_app(config, platform, opts)
    end
    alias_method "build_extension", "build"
    alias_method "build", "build_watch_extension"
  end
end; end
