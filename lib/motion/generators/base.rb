require 'erb'

module Motion
  module Generators
    class Base
      def initialize(name)
        @name = name
      end
      
      def directory(name)
        Motion::Project::App.log 'Directory', name
        FileUtils.mkdir_p(name)
      end
      
      def file(name, source)
        Motion::Project::App.log 'Create', name
        content = File.read("#{template_dir}/#{source}")
        File.open(name, 'w') { |file| file.print content }
      end
      
      def template(name, source)
        Motion::Project::App.log 'Create', name
        content = File.read("#{template_dir}/#{source}")
        File.open(name, 'w') { |file| file.print ERB.new(content).result(binding) }
      end
      
      def generate!
        raise NotImplementedError
      end
      
    private
      def template_dir
        File.join(File.dirname(__FILE__), generator_name, 'templates')
      end
      
      def generator_name
        self.class.name.gsub(/.*::/, '').gsub(/Generator/, '').downcase
      end
    end
  end
end
