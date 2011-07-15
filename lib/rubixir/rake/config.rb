module Rubixir
  class Config
    attr_accessor :files, :platforms_dir, :sdk_version, :frameworks,
      :app_delegate_class, :app_name, :build_dir

    def initialize(project_dir)
      @files = Dir.glob(File.join(project_dir, 'app/**/*.rb'))
      @platforms_dir = '/Developer/Platforms'
      @sdk_version = '4.3'
      @frameworks = ['UIKit', 'Foundation', 'CoreGraphics']
      @app_delegate_class = 'AppDelegate'
      @app_name = 'My App'
      @build_dir = File.join(project_dir, 'build')
    end

    def platform_dir(platform)
      File.join(@platforms_dir, platform + '.platform')
    end

    def sdk(platform)
      File.join(platform_dir(platform), 'Developer/SDKs',
        platform + @sdk_version + '.sdk')
    end
  end
end
