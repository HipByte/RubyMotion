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

module Motion; module Project
class REPLLauncher
  VALID_VARS = %w(verbose arguments debug-mode spec-mode start-suspended
                  background-fetch kernel-path xcode-path device-hostname
                  local-port remote-port uses-bs display-type platform device-name
                  device-family app-bundle-path sdk-version bs_files watchkit-launch-mode
                  watchkit-notification-payload device-id)

  def initialize(opts)
    opts.each do |key, value|
      unless VALID_VARS.include?(key.to_s)
        App.fail("Invalid option for jit-bridge: `#{key}'")
      end
    end
    @opts = opts
  end

  def variables
    map = {}
    @opts.each do |key, value|
      map[key] = value if !value.nil?
    end
    map
  end

  def arguments
    args = ''
    variables.map do |key, value|
      if value == true
        args << " --#{key}"
      elsif value
        if key == "bs_files"
          args << value.map { |v| " --uses-bs \"#{File.expand_path(v)}\"" }.join('')
        else
          args << " --#{key} \"#{value}\""
        end
      end
    end
    args
  end

  def launch_cmd
    repl = File.join(App.config.bindir, 'repl')
    "\"#{repl}\" #{arguments}"
  end

  def launch
    command = launch_cmd
    puts command if App::VERBOSE
    system(command)
  end
end
end; end
