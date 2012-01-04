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
        cat_element(plist, str, 1)
        str << "</plist>\n"
        return str
      end
 
      def indent_line(line, indent)
        ("\t" * indent) + line + "\n"
      end
 
      def cat_element(plist, str, indent)
        case plist
          when Hash
            str << indent_line("<dict>", indent)
            plist.each do |key, val|
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
          else
            raise "Invalid plist object of type `#{plist.class}' (must be either a Hash, Array, String, or boolean true/false value)"
        end
      end
    end
  end
end
