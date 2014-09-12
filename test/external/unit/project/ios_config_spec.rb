require File.expand_path('../../../spec_helper', __FILE__)
#require 'motion/project/xcode_config'
require 'motion/project/template/ios/config'

require 'tempfile'

module Motion; module Project
  describe IOSConfig do
    describe "concerning UILaunchImages" do
      before do
        @config = IOSConfig.new(Dir.tmpdir, :development)
        @config.deployment_target = '7.0'
      end

      it "does not try to include UILaunchImages on a deployment target older than iOS 7" do
        @config.deployment_target = '6.1'
        Dir.expects(:glob).never
        @config.launch_images
      end

      it "infers the launch images from the specified resources by the Default prefix and png extname" do
        Dir.expects(:glob).with(File.join(@config.resources_dirs.first, 'Default*.png')).returns(['resources/Default.png'])
        @config.expects(:launch_image_metadata).with('resources/Default.png')
        @config.launch_images
      end

      it "disallows non-PNGs" do
        @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default.png'")
                           .returns("  format: jpeg\n  pixelWidth: 320\n  pixelHeight: 480\n")
        App.expects(:fail)
        @config.launch_image_metadata("resources/Default.png")
      end

      it "disallows a height filename component not matching the actual height" do
        @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default-568h.png'")
                           .returns("  format: png\n  pixelWidth: 320\n  pixelHeight: 480\n")
        App.expects(:fail)
        @config.launch_image_metadata("resources/Default-568h.png")
      end

      it "configures a non-retina iPhone < 5 image" do
        @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default.png'")
                           .returns("  format: png\n  pixelWidth: 320\n  pixelHeight: 480\n")
        @config.launch_image_metadata("resources/Default.png").should == {
          "UILaunchImageMinimumOSVersion" => "7.0",
          "UILaunchImageName" => "Default",
          "UILaunchImageOrientation" => "Portrait",
          "UILaunchImageSize" => "{320, 480}"
        }
      end

      it "configures a retina iPhone < 5 image" do
        @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default@2x.png'")
                           .returns("  format: png\n  pixelWidth: 640\n  pixelHeight: 960\n")
        @config.launch_image_metadata("resources/Default@2x.png").should == {
          "UILaunchImageMinimumOSVersion" => "7.0",
          "UILaunchImageName" => "Default",
          "UILaunchImageOrientation" => "Portrait",
          "UILaunchImageSize" => "{320, 480}"
        }
      end

      it "configures an iPhone 5 image" do
        @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default-568h@2x.png'")
                           .returns("  format: png\n  pixelWidth: 640\n  pixelHeight: 1136\n")
        @config.launch_image_metadata("resources/Default-568h@2x.png").should == {
          "UILaunchImageMinimumOSVersion" => "7.0",
          "UILaunchImageName" => "Default",
          "UILaunchImageOrientation" => "Portrait",
          "UILaunchImageSize" => "{320, 568}"
        }
      end

      it "configures an iPhone 6 image" do
        @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default-667h@2x.png'")
                           .returns("  format: png\n  pixelWidth: 750\n  pixelHeight: 1334\n")
        @config.launch_image_metadata("resources/Default-667h@2x.png").should == {
          #"UILaunchImageMinimumOSVersion" => "8.0",
          "UILaunchImageMinimumOSVersion" => "7.0",
          "UILaunchImageName" => "Default",
          "UILaunchImageOrientation" => "Portrait",
          "UILaunchImageSize" => "{375, 667}"
        }
      end

      it "configures an iPhone 6+ image" do
        @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default-736h@3x.png'")
                           .returns("  format: png\n  pixelWidth: 1242\n  pixelHeight: 2208\n")
        @config.launch_image_metadata("resources/Default-736h@3x.png").should == {
          #"UILaunchImageMinimumOSVersion" => "8.0",
          "UILaunchImageMinimumOSVersion" => "7.0",
          "UILaunchImageName" => "Default",
          "UILaunchImageOrientation" => "Portrait",
          "UILaunchImageSize" => "{414, 736}"
        }
      end

      {
        ''                    => 'Portrait',
        '-Portrait'           => 'Portrait',
        '-PortraitUpsideDown' => 'PortraitUpsideDown',
        '-Landscape'          => 'Landscape',
        '-LandscapeLeft'      => 'LandscapeLeft',
        '-LandscapeRight'     => 'LandscapeRight',
      }.each do |orientation_component, expected_orientation|
        it "configures a non-retina iPad #{expected_orientation} image (e.g. iPad 2)" do
          @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default#{orientation_component}~ipad.png'")
                             .returns("  format: png\n  pixelWidth: 768\n  pixelHeight: 1024\n")
          @config.launch_image_metadata("resources/Default#{orientation_component}~ipad.png").should == {
            "UILaunchImageMinimumOSVersion" => "7.0",
            "UILaunchImageName" => "Default",
            "UILaunchImageOrientation" => expected_orientation,
            "UILaunchImageSize" => "{768, 1024}"
          }
        end

        it "configures a retina iPad #{expected_orientation} image" do
          @config.expects(:`).with("/usr/bin/sips -g format -g pixelWidth -g pixelHeight 'resources/Default#{orientation_component}@2x~ipad.png'")
                             .returns("  format: png\n  pixelWidth: 1536\n  pixelHeight: 2048\n")
          @config.launch_image_metadata("resources/Default#{orientation_component}@2x~ipad.png").should == {
            "UILaunchImageMinimumOSVersion" => "7.0",
            "UILaunchImageName" => "Default",
            "UILaunchImageOrientation" => expected_orientation,
            "UILaunchImageSize" => "{768, 1024}"
          }
        end
      end
    end
  end

end; end
