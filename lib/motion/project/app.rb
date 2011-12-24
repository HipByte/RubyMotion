module Motion; module Project
  class App
    class << self
      def config
        @config ||= Motion::Project::Config.new('.')
      end

      def builder
        @builder ||= Motion::Project::Builder.new
      end

      def setup
        yield config
        config.validate
      end

      def build(platform)
        builder.build(config, platform)
      end

      def codesign(platform)
        builder.codesign(config, platform)
      end

      def warn(msg)
        $stderr.puts "WARNING!".rjust(10) + ' ' + msg
      end

      def info(what, msg)
        unless Rake.verbose
          $stderr.puts what.rjust(10) + ' ' + msg 
        end
      end
    end
  end
end; end
