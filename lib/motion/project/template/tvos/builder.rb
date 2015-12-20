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

require 'motion/project/builder'

module Motion; module Project
  class Builder
    def archive(config)
      # Create .ipa archive.
      app_bundle = config.app_bundle('AppleTVOS')
      archive = config.archive
      if !File.exist?(archive) or File.mtime(app_bundle) > File.mtime(archive)
        App.info 'Create', archive
        tmp = "/tmp/ipa_root"
        sh "/bin/rm -rf #{tmp}"
        sh "/bin/mkdir -p #{tmp}/Payload"
        sh "/bin/cp -r \"#{app_bundle}\" #{tmp}/Payload"
        sh "/bin/chmod -R 755 #{tmp}/Payload"
        Dir.chdir(tmp) do
          dirs = Dir.glob("*").join(' ')
          sh "/usr/bin/zip -q -r archive.zip #{dirs}"
        end
        sh "/bin/cp #{tmp}/archive.zip \"#{archive}\""
      end

      # Create manifest file (if needed).
      manifest_plist = File.join(config.versionized_build_dir('AppleTVOS'), 'manifest.plist')
      manifest_plist_data = config.manifest_plist_data
      if manifest_plist_data and (!File.exist?(manifest_plist) or File.mtime(config.project_file) > File.mtime(manifest_plist))
        App.info 'Create', manifest_plist
        File.open(manifest_plist, 'w') { |io| io.write(manifest_plist_data) }
      end
    end

    def codesign(config, platform)
      bundle_path = config.app_bundle(platform)
      raise unless File.exist?(bundle_path)

      # Codesign targets
      unless config.targets.empty?
        config.targets.each do |target|
          target.codesign(platform)
        end
      end

      # Copy the provisioning profile.
      bundle_provision = File.join(bundle_path, "embedded.mobileprovision")
      App.info 'Create', bundle_provision
      FileUtils.cp config.provisioning_profile, bundle_provision

      # Codesign.
      codesign_cmd = "CODESIGN_ALLOCATE=\"#{File.join(config.xcode_dir, 'Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate')}\" /usr/bin/codesign"

      app_frameworks = File.join(config.app_bundle(platform), 'Frameworks')
      config.embedded_frameworks.each do |framework|
        framework_path = File.join(app_frameworks, File.basename(framework))
        if File.mtime(config.project_file) > File.mtime(framework_path) \
            or !system("#{codesign_cmd} --verify \"#{framework_path}\" >& /dev/null")
          App.info 'Codesign', framework_path
          sh "#{codesign_cmd} -f -s \"#{config.codesign_certificate}\" --preserve-metadata=\"identifier,entitlements,resource-rules\" \"#{framework_path}\""
        end
      end

      if File.mtime(config.project_file) > File.mtime(bundle_path) \
          or !system("#{codesign_cmd} --verify \"#{bundle_path}\" >& /dev/null")
        App.info 'Codesign', bundle_path
        entitlements = File.join(config.versionized_build_dir(platform), "Entitlements.plist")
        File.open(entitlements, 'w') { |io| io.write(config.entitlements_data) }
        sh "#{codesign_cmd} -f -s \"#{config.codesign_certificate}\" --entitlements #{entitlements} \"#{bundle_path}\""
      end
    end
  end
end; end
