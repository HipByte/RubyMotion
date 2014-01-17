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

module Motion; module Project; class Command
  class Activate < Command
    self.summary = 'Activate software license.'
    self.description = 'Activate your RubyMotion software license key.'

    self.arguments = 'LICENSE-KEY'

    def initialize(argv)
      @license_key = argv.shift_argument
      super
    end

    def validate!
      super
      help! "Activating a license requires a `LICENSE-KEY`." unless @license_key
    end

    def run
      if File.exist?(LicensePath)
        die "Product is already activated. Delete the license file `#{LicensePath}' if you want to activate a new license."
      end

      unless @license_key.match(/^[a-f0-9]{40}$/)
        die "Given license key `#{@license_key}' seems invalid. It should be a string of 40 hexadecimal characters. Check the mail you received after the order, or contact us if you need any help: info@hipbyte.com"
      end

      need_root
      File.open(LicensePath, 'w') { |io| io.write license_key }
      puts "Product activated. Thanks for purchasing RubyMotion :-)"
    end
  end
end; end; end
