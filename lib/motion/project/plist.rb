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

require 'time' # For Time#iso8601

module Motion
  class PropertyList
    class << self
      def to_s(plist)
        str = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
EOS
        cat_element(plist, str, 1)
        str << "</plist>\n"
        str
      end

      def indent_line(line, indent)
        ("\t" * indent) + line + "\n"
      end

      def cat_element(plist, str, indent)
        case plist
          when Hash
            str << indent_line("<dict>", indent)
            plist.each do |key, val|
              key = key.to_s if key.is_a?(Symbol)
              raise "Hash key must be a string" unless key.is_a?(String)
              str << indent_line("<key>#{key}</key>", indent + 1)
              cat_element(val, str, indent + 1)
            end
            str << indent_line("</dict>", indent)
          when Array
            str << indent_line("<array>", indent)
            plist.each do |elem|
              cat_element(elem, str, indent + 1)
            end
            str << indent_line("</array>", indent)
          when String
            str << indent_line("<string>#{plist}</string>", indent)
          when TrueClass
            str << indent_line("<true/>", indent)
          when FalseClass
            str << indent_line("<false/>", indent)
          when Time
            str << indent_line("<date>#{plist.utc.iso8601}</date>", indent)
          when Integer
            str << indent_line("<integer>#{plist}</integer>", indent)
          else
            raise "Invalid plist object of type `#{plist.class}' (must be either a Hash, Array, String, or boolean true/false value)"
        end
      end
    end
  end
end
