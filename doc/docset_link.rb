class DocsetGenerator
  class Linker
    require 'nokogiri'
    require 'fileutils'

    def get_module_list
      files = Dir.glob(File.join(@dir_path, "*.html"))
      files.map { |x| File.basename(x, ".html") }
    end

    def initialize(dir_path)
      @dir_path = dir_path
      @module_list = get_module_list
    end

    def run(file_path)
      data = File.read(file_path)
      doc = Nokogiri::HTML(data)

      is_update = false
      nodes = []
      nodes.concat(doc.xpath(".//div[@class='inline']/p"))
      nodes.concat(doc.xpath(".//div[@class='docstring']/div[@class='discussion']/p"))
      nodes.each do |node|
        text = node.text
        node.text.scan(/([A-Z]\w*)/).uniq.each do |item|
          word = item.first
          if @module_list.include?(word)
            text.gsub!(word, "<a href='#{word}.html'>#{word}</a>")
            is_update = true
          end
        end
        node.inner_html = text
      end

      if is_update
        File.open(file_path, "w") { |io| io.puts doc.to_html }
      end
    end
  end
end