require File.expand_path('../../../spec_helper', __FILE__)
require 'motion/util/code_sign'

module SpecHelper
  module Fixtures
    NO_CODESIGN_IDENTITIES = <<-EOS

Policy: Code Signing
  Matching identities
    0 identities found
EOS

    ALL_CODESIGN_IDENTITIES = <<-EOS

Policy: Code Signing
  Matching identities
  1) 5DD1D0DB197456F156D58D0F176200FB18840923 "Developer ID Application: Fingertips B.V."
  2) 689D97626D58D0F11F26AE048CBAD0FFB53545C9 "iPhone Developer: Eloy Duran (K5B8YH2WD5)"
  3) 01D976265D06F156D585560DB19740AD053C1162 "Mac Developer Self-Signed for Eloy Durán" (CSSMERR_TP_INVALID_ANCHOR_CERT)
     3 identities found

  Valid identities only
  1) 5DD1D0DB197456F156D58D0F176200FB18840923 "Developer ID Application: Fingertips B.V."
  2) 689D97626D58D0F11F26AE048CBAD0FFB53545C9 "iPhone Developer: Eloy Duran (K5B8YH2WD5)"
     2 valid identities found
EOS

    VALID_CODESIGN_IDENTITIES = <<-EOS
  1) 5DD1D0DB197456F156D58D0F176200FB18840923 "Developer ID Application: Fingertips B.V."
  2) 689D97626D58D0F11F26AE048CBAD0FFB53545C9 "iPhone Developer: Eloy Duran (K5B8YH2WD5)"
     2 valid identities found
EOS
  end
end

module Motion; module Util

  describe CodeSign do
    it "queries the security database for all codesigning identities" do
      CodeSign.expects(:`).with('/usr/bin/security -q find-identity -p codesigning').returns(' ALL ')
      CodeSign.query_security_db_for_identities(false).should == 'ALL'
    end

    it "queries the security database for valid codesigning identities" do
      CodeSign.expects(:`).with('/usr/bin/security -q find-identity -p codesigning -v').returns(' VALID ')
      CodeSign.query_security_db_for_identities(true).should == 'VALID'
    end

    it "returns an empty list if there are no codesigning identities" do
      CodeSign.stubs(:query_security_db_for_identities).returns(SpecHelper::Fixtures::NO_CODESIGN_IDENTITIES)
      CodeSign.identities(false).should == {}
    end

    before do
      CodeSign.stubs(:query_security_db_for_identities).with(false).returns(SpecHelper::Fixtures::ALL_CODESIGN_IDENTITIES)
      CodeSign.stubs(:query_security_db_for_identities).with(true).returns(SpecHelper::Fixtures::VALID_CODESIGN_IDENTITIES)
    end

    it "returns all codesign identities" do
      CodeSign.identities(false).should == {
        '5DD1D0DB197456F156D58D0F176200FB18840923' => 'Developer ID Application: Fingertips B.V.',
        '689D97626D58D0F11F26AE048CBAD0FFB53545C9' => 'iPhone Developer: Eloy Duran (K5B8YH2WD5)',
        '01D976265D06F156D585560DB19740AD053C1162' => 'Mac Developer Self-Signed for Eloy Durán',
      }
    end

    it "returns only valid identities" do
      CodeSign.identities(true).should == {
        '5DD1D0DB197456F156D58D0F176200FB18840923' => 'Developer ID Application: Fingertips B.V.',
        '689D97626D58D0F11F26AE048CBAD0FFB53545C9' => 'iPhone Developer: Eloy Duran (K5B8YH2WD5)',
      }
    end

    it "returns all codesign identity names" do
      CodeSign.identity_names(false).should == [
        'Developer ID Application: Fingertips B.V.',
        'iPhone Developer: Eloy Duran (K5B8YH2WD5)',
        'Mac Developer Self-Signed for Eloy Durán',
      ]
    end

    it "returns only valid identity names" do
      CodeSign.identity_names(true).should == [
        'Developer ID Application: Fingertips B.V.',
        'iPhone Developer: Eloy Duran (K5B8YH2WD5)',
      ]
    end
  end

end; end

