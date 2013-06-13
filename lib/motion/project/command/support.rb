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

require 'uri'

module Motion; module Project
  class SupportCommand < Command
    self.name = 'support'
    self.help = 'Create a support ticket'
  
    def run(args)
      unless args.empty?
        die "Usage: motion support"
      end
  
      license_key = read_license_key
      email = guess_email_address
  
      # Collect details about the environment.
      osx_vers = `/usr/bin/sw_vers -productVersion`.strip
      rm_vers = Motion::Version
      xcode_vers = begin
        xcodebuild = `which xcodebuild`.strip
        xcodebuild = '/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild' if xcodebuild.empty?
        vers = ''
        if File.exist?(xcodebuild)
          vers = `#{xcodebuild} -version`.strip.scan(/Xcode\s(.+)$/).flatten[0].to_s
        end
        vers = 'unknown' if vers.empty?
        vers
      end
  
      environment = URI.escape("OSX #{osx_vers}, RubyMotion #{rm_vers}, Xcode #{xcode_vers}")
  
      system("open \"https://secure.rubymotion.com/new_support_ticket?license_key=#{license_key}&email=#{email}&environment=#{environment}\"")
    end
  end
end; end
