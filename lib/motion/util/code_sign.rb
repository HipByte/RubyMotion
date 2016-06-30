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

module Motion; module Util
  module CodeSign
    class << self
      # @param [Boolean] valid_only
      #        Whether or not to include _only_ valid code sign identities.
      #
      # @return [String] The raw output from querying the `security` DB.
      #
      def query_security_db_for_identities(valid_only)
        command = '/usr/bin/security -q find-identity -p codesigning'
        command << ' -v' if valid_only
        `#{command}`.strip
      end

      # @param [Boolean] valid_only
      #        Whether or not to include _only_ valid code sign identities.
      #
      # @return [Hash{String => String}] The UUIDs and names of the identities.
      #
      def identities(valid_only)
        output = query_security_db_for_identities(valid_only)
        Hash[*output.scan(/(\h{40})\s"(.+?)"/).flatten]
      end

      # @param [Boolean] valid_only
      #        Whether or not to include _only_ valid code sign identities.
      #
      # @return [Array<String>] The names of the identities.
      #
      def identity_names(valid_only)
        identities(valid_only).values
      end
    end
  end
end; end
