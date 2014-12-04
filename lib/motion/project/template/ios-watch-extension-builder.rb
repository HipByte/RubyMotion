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
      # Copy watch app binary
      FileUtils.mkdir_p config.app_bundle(platform)
      source = config.prebuilt_app_executable(platform)
      destination = config.app_bundle_executable(platform)
      sh "/usr/bin/ditto -rsrc '#{source}' '#{destination}'"

      # Compile storyboard
      sh "/usr/bin/ibtool --errors --warnings --notices --module #{config.escaped_storyboard_module_name} --minimum-deployment-target #{config.sdk_version} --output-partial-info-plist /tmp/Interface-SBPartialInfo.plist --auto-activate-custom-fonts --output-format human-readable-text --compilation-directory '#{config.app_bundle(platform)}' watch_app/Interface.storyboard"

      # Create bundle/Info.plist.
      generate_info_plist(config, platform)
    end

    def build_watch_extension(config, platform, opts)
      build_extension(config, platform, opts)
      build_watch_app(config.watch_app_config, platform, opts)
    end
    alias_method "build_extension", "build"
    alias_method "build", "build_watch_extension"
  end
end; end
