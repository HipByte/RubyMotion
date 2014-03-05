# encoding: utf-8

require 'find'

class MagicEncoding
  MAGIC_ENCODING = "# encoding: utf-8\n\n"
  SOURCE_FILE_RE = /\.(rb|rake)$/

  def self.fix(content)
    MAGIC_ENCODING + content.lstrip
  end

  def self.change?(filename)
    File.open(filename) do |file|
      if file.read(10) != '# encoding'
        file.seek(0)
        file.read
      end
    end
  end

  def self.files(count)
    "#{count} #{count == 1 ? 'file' : 'files'}"
  end

  def self.apply(root)
    ignored = 0
    fixed = 0

    Find.find(root) do |filename|
      if File.file?(filename)
        next if filename.match(/\/template\/.+\/files\//)
        if filename =~ SOURCE_FILE_RE
          if content = change?(filename)
            File.open(filename, 'w') do |file|
              file.write(fix(content))
            end
            fixed += 1
          else
            ignored += 1
          end
        end
      end
    end

    puts "Fixed #{files(fixed)}, #{files(ignored)} were already fine."
  end
end
