require File.expand_path('../../../spec_helper', __FILE__)
require 'motion/project/xcode_config'

require 'tempfile'

module Motion; module Project

  describe XcodeConfig do
    describe "concerning codesign certificates" do
      before do
        Util::CodeSign.stubs(:identity_names).with(false).returns([
          'iPhone Developer: Eloy Duran (K5B8YH2WD5)',
          'Mac Developer Self-Signed for Eloy Durán',
          'Mac Developer: Eloy Duran (K5B8YH2WD5)',
        ])
        App.stubs(:warn)
        @config = XcodeConfig.new(Dir.tmpdir, :development)
      end

      it "selects an identity meant for codesigning iPhone apps" do
        @config.codesign_certificate('iPhone').should == 'iPhone Developer: Eloy Duran (K5B8YH2WD5)'
      end

      it "selects an identity meant for codesigning Mac apps" do
        @config.codesign_certificate('Mac').should == 'Mac Developer Self-Signed for Eloy Durán'
      end

      it "warns when there are multiple matching identities" do
        App.expects(:warn)
        @config.codesign_certificate('Mac')
      end

      it "fails when there no identities could be found" do
        App.expects(:fail)
        @config.codesign_certificate('Android')
      end

      it "limits identities to valid ones in release mode" do
        Util::CodeSign.stubs(:identity_names).with(true).returns([
          'iPhone Developer: Eloy Duran (K5B8YH2WD5)',
          'Mac Developer: Eloy Duran (K5B8YH2WD5)',
        ])
        @config.instance_variable_set(:@build_mode, :release)
        @config.codesign_certificate('Mac').should == 'Mac Developer: Eloy Duran (K5B8YH2WD5)'
      end
    end
  end

end; end
