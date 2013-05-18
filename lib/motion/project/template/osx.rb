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

App = Motion::Project::App
App.template = :osx

require 'motion/project'
require 'motion/project/template/osx/config'
require 'motion/project/template/osx/builder'

desc "Build the project, then run it"
task :default => :run

namespace :build do
  desc "Build the project for development"
  task :development do
    App.build('MacOSX')
  end

  desc "Build the project for release"
  task :release do
    App.config_without_setup.build_mode = :release
    App.build('MacOSX')
  end
end

desc "Run the project"
task :run => 'build:development' do
  exec = App.config.app_bundle_executable('MacOSX')
  env = ''
  env << 'SIM_SPEC_MODE=1' if App.config.spec_mode
  sim = File.join(App.config.bindir, 'osx/sim')
  debug = ((ENV['debug'] || ENV['DEBUG']) ? 1 : (App.config.spec_mode ? '0' : '2'))
  target = App.config.sdk_version
  App.info 'Run', exec
  at_exit { system("stty echo") } if $stdout.tty? # Just in case the process crashes and leaves the terminal without echo.
  sh "#{env} #{sim} #{debug} #{target} \"#{exec}\""
end

desc "Run the test/spec suite"
task :spec do
  App.config.spec_mode = true
  Rake::Task["run"].invoke
end

desc "Create a .pkg archive"
task :archive => 'build:release' do
  App.codesign('MacOSX')
  App.archive
end

namespace :archive do
  desc "Create a .pkg archive for distribution (AppStore)"
  task :distribution do
    App.config.distribution_mode = true
    Rake::Task['archive'].invoke
  end
end
