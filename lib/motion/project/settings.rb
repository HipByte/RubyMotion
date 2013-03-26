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

require 'yaml'

module Motion; module Project
  class Settings
    def self.setup
      instance = allocate
      instance.custom_initializer
      instance
    end

    def custom_initializer
      [user_file, app_file].each {|file| create_file(file) unless File.exist?(file)} 
      environmentize(user_settings)
      environmentize(app_settings) do |key|
        App.warn "#{key} has been overridden" if user_settings[key]
      end
    end

    def user_file
      @user_file ||= File.expand_path('~/.motion-settings.yml')
    end

    def user_settings
      @user_settings ||= parse(user_file)
    end

    def app_file
      @app_file ||= File.expand_path('.motion-settings.yml')
    end

    def app_settings
      @app_settings ||= parse(app_file)
    end

  private

    def environmentize(settings, &block)
      settings.each do |key, value|
        block.call(key) if block_given?
        ENV[key] = value
      end
    end

    def parse(file)
      # catch exception for a bug in ruby-1.9.3p194
      # https://bugs.ruby-lang.org/issues/6487
      begin
        YAML.load_file(file) || {}
      rescue TypeError
        {}
      end
    end

    def create_file(file)
      FileUtils.touch(file)
      App.log 'Create', file
    end

  end
end; end

Motion::Project::App.setup do |app|
  Motion::Project::Settings.setup
end