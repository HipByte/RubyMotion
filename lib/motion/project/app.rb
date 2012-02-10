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
      def config_mode
        @config_mode or :development
      end

      def config_mode=(mode)
        @config_mode = mode
      end

      def configs
        @configs ||= {
          :development => Motion::Project::Config.new('.', :development),
          :release => Motion::Project::Config.new('.', :release)
        }
      end

      def config
        configs[config_mode]
      end

      def builder
        @builder ||= Motion::Project::Builder.new
      end

      def setup
        configs.each_value { |x| yield x }
        config.validate
      end

      def build(platform)
        builder.build(config, platform)
      end

      def archive
        builder.archive(config)
      end

      def codesign(platform)
        builder.codesign(config, platform)
      end

      def log(what, msg)
        @print_mutex ||= Mutex.new
        # Because this method can be called concurrently, we don't want to mess any output.
        @print_mutex.synchronize do
          what = "\e[1m" + what.rjust(10) + "\e[0m" # bold
          $stderr.puts what + ' ' + msg 
        end
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
