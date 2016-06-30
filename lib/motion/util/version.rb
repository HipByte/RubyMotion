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
  class Version
    include Comparable

    def initialize(version)
      @version = version.to_s
      unless @version =~ /^[.0-9]+$/
        raise ArgumentError, "A version may only contain periods and digits."
      end
    end

    def to_s
      @version
    end

    def segments
      @segments ||= @version.split('.').map(&:to_i)
    end

    # This is pretty much vendored straight from RubyGems, except we don't
    # care about string segments for our purposes.
    #
    # https://github.com/rubygems/rubygems/blob/81d806d818baeb5dcb6398ca631d772a003d078e/lib/rubygems/version.rb
    #
    def <=>(other)
      other = Version.new(other) if String === other
      return unless Version === other
      return 0 if @version == other.to_s

      lhsegments = segments
      rhsegments = other.segments

      lhsize = lhsegments.size
      rhsize = rhsegments.size
      limit  = (lhsize > rhsize ? lhsize : rhsize) - 1

      i = 0
      while i <= limit
        lhs = lhsegments[i] || 0
        rhs = rhsegments[i] || 0
        i += 1
        next if lhs == rhs
        return lhs <=> rhs
      end

      0
    end
  end
end; end
