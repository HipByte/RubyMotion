# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)

describe "Time#eql?" do
  it "returns true if self and other have the same whole number of seconds" do
    Time.at(100).eql?(Time.at(100)).should == true
  end

  it "returns false if self and other have differing whole numbers of seconds" do
    Time.at(100).eql?(Time.at(99)).should == false
  end

  it "returns true if self and other have the same number of microseconds" do
    Time.at(100, 100).eql?(Time.at(100, 100)).should == true
  end

  it "returns false if self and other have differing numbers of microseconds" do
    Time.at(100, 100).eql?(Time.at(100, 99)).should == false
  end

  ruby_version_is "1.9" do
    it "returns false if self and other have differing fractional microseconds" do
      Time.at(100, Rational(100,1000)).eql?(Time.at(100, Rational(99,1000))).should == false
    end
  end

  it "returns false when given a non-time value" do
    Time.at(100, 100).eql?("100").should == false
    Time.at(100, 100).eql?(100).should == false
    Time.at(100, 100).eql?(100.1).should == false
  end
end
