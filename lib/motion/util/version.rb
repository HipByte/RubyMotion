# encoding: utf-8

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
