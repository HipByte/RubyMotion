require File.expand_path('../../../spec_helper', __FILE__)
require 'motion/util/version'

module Motion; module Util

  describe Version do
    it "raises if given a string that contains other chars than dots and digits" do
      lambda { Version.new(' 1') }.should.raise ArgumentError
      lambda { Version.new('1,0') }.should.raise ArgumentError
      lambda { Version.new('1.0b1') }.should.raise ArgumentError
    end

    before do
      @version = Version.new('10.6.1')
    end

    it "returns its segments" do
      @version.segments.should == [10, 6, 1]
    end

    it "is comparable to other versions" do
      @version.should == Version.new('10.6.1')
      @version.should == Version.new('10.6.1.0')
      @version.should <= Version.new('10.6.1.0.0')
      @version.should >= Version.new('10.6.1.0.0.0')

      @version.should > Version.new('10.6.0')
      @version.should > Version.new('9.5.99.0')

      @version.should < Version.new('10.6.1.1')
      @version.should < Version.new('11.0.0.1')
    end

    it "returns a string representation" do
      @version.to_s.should == '10.6.1'
    end

    it "creates a new instance from an existing instance" do
      other = Version.new(@version)
      other.should == @version
      other.should.not.eql @version
    end
  end

end; end
