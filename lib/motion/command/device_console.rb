# Copyright (c) 2013, HipByte SPRL and contributors
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

module Motion; class Command
  class DeprecatedDeviceConsole < Command
    self.command = 'device:console'

    def run
      warn "[!] The usage of the `device:console` command is deprecated" \
           "use the `device-console` command instead."
      DeviceConsole.run([])
    end
  end

  class DeviceConsole < Command
    self.summary = 'Print iOS device logs'

    def run
      deploy = File.join(File.dirname(__FILE__), '../../../../bin/ios/deploy')
      devices = `\"#{deploy}\" -D`.strip.split(/\n/)
      if devices.empty?
        $stderr.puts "No device found on USB. Connect a device and try again." 
      elsif devices.size > 1
        $stderr.puts "Multiple devices found on USB. Disconnect all but one and try again."
      else
        system("\"#{deploy}\" -c #{devices[0]}")
      end
    end
  end
end; end
