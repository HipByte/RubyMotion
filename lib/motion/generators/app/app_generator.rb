module Motion
  module Generators
    class AppGenerator < Base
      def generate!
        directory @name
        file      "#{@name}/.gitignore", 'gitignore'
        template  "#{@name}/Rakefile", 'Rakefile.erb'
        directory "#{@name}/app"
        file      "#{@name}/app/app_delegate.rb", 'app_delegate.rb'
        directory "#{@name}/resources"
        file      "#{@name}/resources/Default-568h@2x.png", 'Default-568h@2x.png'
        directory "#{@name}/spec"
        template  "#{@name}/spec/main_spec.rb", 'main_spec.erb'
      end
    end
  end
end
