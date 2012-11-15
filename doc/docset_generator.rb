require 'rubygems'
require 'nokogiri'
require 'sqlite3'

class DocsetGenerator
  class Generator
    TYPE_CLASS     = "cl"
    TYPE_METHOD    = "clm"
    TYPE_CATEGORY  = "cat"
    TYPE_CONSTANT  = "clconst"
    TYPE_PROTOCOL  = "intf"
    TYPE_ATTRIBUTE = "Attribute"

    attr_accessor :entries

    def initialize
      @entries = []
    end

    def add_entry(entry)
      @entries << entry
    end

    def convert_type(type)
      case type
      when "Class", "Module", "Exception", "Enumeration"
        TYPE_CLASS
      when "Protocol"
        TYPE_PROTOCOL
      end
    end

    def parse_title(doc, file_path)
      title = doc.xpath('/html/head/title')
      if match = title.text.strip.match(/([^:]+):\s*(.+)/)
        type = match[1]
        name = match[2]
        add_entry(Entry.new(name, convert_type(type), file_path))
      end
    end

    def parse_constant(doc, file_path)
      consts = doc.xpath('//dl[@class="constants"]/dt')
      consts.each do |const|
        const.xpath('./div[@class="docstring"]').remove
        name = const.text.strip
        path = "#{file_path}##{const.attribute('id').value}"
        add_entry(Entry.new(name, TYPE_CONSTANT, path))
      end
    end

    def parse_method(doc, file_path)
      methods = doc.xpath('//ul[@class="summary"]/li[@class="public "]')
      methods.each do |method|
        meth = method.xpath('./span[@class="summary_signature"]/a')
        name = meth.text.sub(/^(\-|\+)/, '').strip
        path = "#{file_path}#{meth.attribute('href').value}"
        add_entry(Entry.new(name, TYPE_METHOD, path))
      end

    end

    def parse(document_dir, file_path)
      doc = Nokogiri::HTML(File.read(File.join(document_dir, file_path)))
      parse_title(doc, file_path)
      parse_constant(doc, file_path)
      parse_method(doc, file_path)
    end

    def index(resource_dir)
      db = DB.new(resource_dir)
      db.insert(@entries)
    end

    class DB
      def initialize(resource_dir)
        path = File.join(resource_dir, "docSet.dsidx")
        File.delete(path) if File.exist?(path)

        @db = SQLite3::Database.new(path)
        create_table()
      end

      def create_table
        @db.execute <<SQL
CREATE TABLE searchIndex (
  id INTEGER PRIMARY KEY,
  name TEXT,
  type TEXT,
  path TEXT
);
SQL
      end

      def insert(entries)
        sql = "insert into searchIndex values (:id, :name, :type, :path)"
        entries.each do |entry|
          @db.execute(sql, :name => entry.name,
                          :type => entry.type,
                          :path => entry.path)
        end
      end
    end

    class Entry
      attr_accessor :name
      attr_accessor :type
      attr_accessor :path

      def initialize(name, type, path)
        @name = name
        @type = type
        @path = path
      end
    end
  end
end
