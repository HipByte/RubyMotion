module Motion
  class App
    class << self
      def config
        @config ||= Motion::Config.new('.')
      end

      def builder
        @builder ||= Motion::Builder.new
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
    end
  end
end
