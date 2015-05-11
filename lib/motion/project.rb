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

require 'motion/version'
require 'motion/project/app'
require 'motion/project/config'
require 'motion/project/builder'
require 'motion/project/vendor'
require 'motion/project/template'
require 'motion/project/plist'

if Motion::Project::App.template == nil
  warn "require 'motion/project' is deprecated, please require 'motion/project/template/ios' instead"
  require 'motion/project/template/ios'
end

unless ENV['RM_TARGET_BUILD']
  # Check for updates.
  motion_bin_path = File.join(File.dirname(__FILE__), '../../bin/motion')
  system("/usr/bin/ruby \"#{motion_bin_path}\" update --check")
end

desc "Deploy on the device"
task :device => :archive do
  App.info 'Deploy', App.config.archive
  device_id = (ENV['id'] or App.config.device_id)
  unless App.config.provisions_all_devices? || App.config.provisioned_devices.include?(device_id)
    App.fail "Device ID `#{device_id}' not provisioned in profile `#{App.config.provisioning_profile}'"
  end
  env = "XCODE_DIR=\"#{App.config.xcode_dir}\""
  deploy = File.join(App.config.bindir, 'deploy')
  flags = Rake.application.options.trace ? '-d' : ''
  sh "#{env} #{deploy} #{flags} \"#{device_id}\" \"#{App.config.archive}\""
end

desc "Clear local build objects"
task :clean do
  App.config.clean_project
end

namespace :clean do
  desc "Clean all build objects"
  task :all do
    Rake::Task["clean"].invoke
    path = Motion::Project::Builder.common_build_dir
    if File.exist?(path)
      App.info 'Delete', path
      rm_rf path
    end
  end
end

desc "Show project config"
task :config do
  map = App.config.variables
  map.keys.sort.each do |key|
    puts key.ljust(22) + " : #{map[key].inspect}"
  end
end

desc "Generate ctags"
task :ctags do
  tags_file = 'tags'
  config = App.config
  if !File.exist?(tags_file) or File.mtime(config.project_file) > File.mtime(tags_file)
    ctags = File.join(config.bindir, 'ctags')
    sh "#{ctags} --options=\"#{config.ctags_config_file}\" #{config.ctags_files.map { |x| '"' + x + '"' }.join(' ')}"
  end
end

# This task does not have a description as it is being used by template Rakefiles instead.
task :__local_crashlog do
  logs = Dir.glob(File.join(File.expand_path("~/Library/Logs/DiagnosticReports/"), "#{App.config.name}_*"))
  if logs.empty?
    $stderr.puts "Unable to find any crash report file"
  else
    sh "/usr/bin/open -a Console \"#{logs.last}\""
  end
end
