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

require 'motion/project/app'
require 'motion/util/version'

App = Motion::Project::App
App.template = :'ios-framework'

unless ENV['RM_TARGET_BUILD']
  App.fail "Framework targets must be built from an application project"
end

require 'motion/project'
require 'motion/project/template/ios-framework/config'
require 'motion/project/template/ios-framework/builder'

desc "Clear local build objects"
task :clean do
  App.config.clean_project(['iPhoneSimulator', 'iPhoneOS'])
end

desc "Build the simulator version"
task :default => :"build:simulator"

desc "Build everything"
task :build => ['build:simulator', 'build:device']

namespace :build do
  def pre_build_actions(platform)
    # TODO: Ensure Info.plist gets regenerated on each build so it has ints for
    # Instruments and strings for normal builds.
    rm_f File.join(App.config.app_bundle(platform), 'Info.plist')

    # TODO this should go into a iOS specific Builder class which performs this
    # check before building.
    App.config.resources_dirs.flatten.each do |dir|
      next unless File.exist?(dir)
      Dir.entries(dir).grep(/^Resources$/i).each do |basename|
        path = File.join(dir, basename)
        if File.directory?(path)
          suggestion = basename == 'Resources' ? 'Assets' : 'assets'
          App.fail "An iOS application cannot be installed if it contains a " \
                   "directory called `resources'. Please rename the " \
                   "directory at path `#{path}' to, for instance, " \
                   "`#{File.join(dir, suggestion)}'."
        end
      end
    end
  end

  desc "Build the simulator version"
  task :simulator do
    pre_build_actions('iPhoneSimulator')
    App.build('iPhoneSimulator')
  end

  desc "Build the device version"
  task :device do
    pre_build_actions('iPhoneOS')
    App.build('iPhoneOS')
  end
end

namespace :archive do
  desc "Build for distribution (AppStore)"
  task :distribution do
    App.config_without_setup.build_mode = :release
    App.config_without_setup.distribution_mode = true
    Rake::Task["build:device"].invoke
  end
end
