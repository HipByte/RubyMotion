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

      def log(what, msg)
        $stderr.puts what.rjust(10) + ' ' + msg 
      end

      def warn(msg)
        log 'WARNING!', msg
      end

      def fail(msg)
        log 'ERROR!', msg
        exit 1
      end

      def info(what, msg)
        log what, msg unless Rake.verbose
      end
    end
  end
end; end
