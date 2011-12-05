# Simple property list helper.
module Motion
  class PropertyList
    class << self
      def to_s(plist)
        str = <<EOS
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
EOS
        cat_element(plist, str)
        str << '</plist>'
        return str
      end
  
      def cat_element(plist, str)
        case plist
          when Hash
            str << '<dict>'
            plist.each do |key, val|
              raise "Hash key must be a string" unless key.is_a?(String)
              str << "<key>#{key}</key>"
              cat_element(val, str)
            end
            str << '</dict>'
          when Array
            str << '<array>'
            plist.each do |elem|
              cat_element(elem, str)
            end
            str << '</array>'
          when String
            str << "<string>#{plist}</string>"
          else
            raise "Invalid plist object (must be either a Hash, Array or String)"
        end
      end
    end
  end
end
