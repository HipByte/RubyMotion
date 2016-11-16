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
      sh "/usr/bin/ditto -rsrc '#{source}' '#{File.join(config.app_bundle(platform), '_WatchKitStub/WK')}'"

      entitlements = File.join(config.app_bundle(platform), "Entitlements.plist")
      File.open(entitlements, 'w') { |io| io.write(config.entitlements_data) }

      watchapp_dir = config.app_bundle(platform)
      bundle_provision = File.join(watchapp_dir, "embedded.mobileprovision")
      App.info 'Create', bundle_provision
      FileUtils.cp config.provisioning_profile, bundle_provision

      # Compile storyboard
      ibtool = File.join(config.xcode_dir, '/usr/bin/ibtool')
      Dir.glob("watch_app/**/Interface.storyboard").each do |storyboard|
        App.info 'Compile', relative_path(storyboard)
        if Util::Version.new(config.xcode_version[0]) >= Util::Version.new('7.0')
          sh "'#{ibtool}' --errors --warnings --notices --target-device watch --module #{config.escaped_storyboard_module_name} --minimum-deployment-target #{config.deployment_target} --output-partial-info-plist /tmp/Interface-SBPartialInfo.plist --auto-activate-custom-fonts --output-format human-readable-text --compilation-directory '/tmp' #{storyboard}"
          sh "'#{ibtool}' --errors --warnings --notices --target-device watch --module #{config.escaped_storyboard_module_name} --minimum-deployment-target #{config.deployment_target} --link '#{File.join(config.app_bundle(platform), 'Base.lproj')}' '/tmp/Interface.storyboardc'"
        else
          compilation_directory = File.join(config.app_bundle(platform), File.dirname(sanitize_destination_path(storyboard)))
          FileUtils.mkdir_p(compilation_directory)
          sh "'#{ibtool}' --errors --warnings --notices --module #{config.escaped_storyboard_module_name} --minimum-deployment-target #{config.deployment_target} --output-partial-info-plist /tmp/Interface-SBPartialInfo.plist --auto-activate-custom-fonts --output-format human-readable-text --compilation-directory '#{compilation_directory}' #{storyboard}"
        end
      end
      # for RM-1016
      system "killall ibtoold 2> /dev/null"

      # Copy localization files
      Dir.glob('watch_app/**/*.strings').each do |res_path|
        dest_path = File.join(config.app_bundle(platform), sanitize_destination_path(res_path))
        copy_resource(res_path, dest_path)
      end

      # Compile asset bundles
      compile_asset_bundles(config, platform)

      # Create bundle/Info.plist.
      generate_info_plist(config, platform)
    end

    def build_watch_extension(config, platform, opts)
      unless ENV['RM_TARGET_BUILD']
        App.fail "Extension targets must be built from an application project"
      end
      build_extension(config, platform, opts)
      build_watch_app(config.watch_app_config, platform, opts)
    end
    alias_method "build_extension", "build"
    alias_method "build", "build_watch_extension"

    def sanitize_destination_path(path)
      path.sub('watch_app/', '')
    end
  end
end; end
