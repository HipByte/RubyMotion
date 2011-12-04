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
    end
  end
end; end
