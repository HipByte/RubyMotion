module Motion
  module Generators
    class GemGenerator < Base
      def generate!
        directory @name
        file      "#{@name}/.gitignore", 'gitignore'
        template  "#{@name}/Rakefile", 'Rakefile.erb'
        template  "#{@name}/Gemfile", 'Gemfile.erb'
        template  "#{@name}/#{@name}.gemspec", 'gemspec.erb'
        directory "#{@name}/app"
        file      "#{@name}/app/app_delegate.rb", 'app_delegate.rb'
        directory "#{@name}/spec"
        directory "#{@name}/lib"
        template  "#{@name}/lib/#{@name}.rb", 'main.erb'
      end
    
    protected
      def user_name
        @user_name ||= %x{git config --global --get user.name}.strip
        @user_name == "" ? 'Insert name here' : @user_name
      end
      
      def user_email
        @user_email ||= %x{git config --global --get user.email}.strip
        @user_email == "" ? 'Insert email here' : @user_email
      end
    end
  end
end
