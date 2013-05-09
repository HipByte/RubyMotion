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
