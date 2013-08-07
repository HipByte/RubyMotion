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

# Check for updates.
motion_bin_path = File.join(File.dirname(__FILE__), '../../bin/motion')
system("/usr/bin/ruby \"#{motion_bin_path}\" update --check")

desc "Clear build objects"
task :clean do
  App.info 'Delete', App.config.build_dir
  rm_rf(App.config.build_dir)
  App.config.vendor_projects.each { |vendor| vendor.clean }
  Dir.glob(App.config.resources_dirs.flatten.map{ |x| x + '/**/*.{nib,storyboardc,momd}' }).each do |p|
    next if File.extname(p) == ".nib" && !File.exist?(p.sub(/\.nib$/, ".xib"))
    App.info 'Delete', p
    rm_rf p
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
    bs_files = config.bridgesupport_files + config.vendor_projects.map { |p| Dir.glob(File.join(p.path, '*.bridgesupport')) }.flatten
    ctags = File.join(config.bindir, 'ctags')
    config = File.join(config.motiondir, 'data', 'bridgesupport-ctags.cfg')
    sh "#{ctags} --options=\"#{config}\" #{bs_files.map { |x| '"' + x + '"' }.join(' ')}"
  end
end

desc "Open the latest crash report generated for the app"
task :crashlog do
  logs = Dir.glob(File.join(File.expand_path("~/Library/Logs/DiagnosticReports/"), "#{App.config.name}_*"))
  if logs.empty?
    $stderr.puts "Unable to find any crash report file"
  else
    sh "open -a Console \"#{logs.last}\""
  end
end
