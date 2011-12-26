module Motion; module Project
  class App
    VERBOSE =
      begin
        if Rake.send(:verbose) != true
          Rake.send(:verbose, false)
          false
        else
          true
        end
      rescue
        true
      end

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
        what = "\e[1m" + what.rjust(10) + "\e[0m" # bold
        $stderr.puts what + ' ' + msg 
      end

      def warn(msg)
        log 'WARNING!', msg
      end

      def fail(msg)
        log 'ERROR!', msg
        exit 1
      end

      def info(what, msg)
        log what, msg unless VERBOSE
      end
    end
  end
end; end
