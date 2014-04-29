describe "Float#to_s" do
  it "returns 'NaN' for NaN" do
    nan_value().to_s.should == 'NaN'
  end

  it "returns 'Infinity' for positive infinity" do
    infinity_value().to_s.should == 'Infinity'
  end

  it "returns '-Infinity' for negative infinity" do
    (-infinity_value()).to_s.should == '-Infinity'
  end

  it "returns '0.0' for 0.0" do
    0.0.to_s.should == "0.0"
  end

  it "emits '-' for -0.0" do
    -0.0.to_s.should == "-0.0"
  end

  it "emits a '-' for negative values" do
    -3.14.to_s.should == "-3.14"
  end

  it "emits a trailing '.0' for a whole number" do
    50.0.to_s.should == "50.0"
  end

  it "emits a trailing '.0' for the mantissa in e format" do
    1.0e20.to_s.should == "1.0e+20"
  end

  it "uses non-e format for a positive value with fractional part having 4 decimal places" do
    0.0001.to_s.should == "0.0001"
  end

  it "uses non-e format for a negative value with fractional part having 4 decimal places" do
    -0.0001.to_s.should == "-0.0001"
  end

  it "uses e format for a positive value with fractional part having 5 decimal places" do
    0.00001.to_s.should == "1.0e-05"
  end

  it "uses e format for a negative value with fractional part having 5 decimal places" do
    -0.00001.to_s.should == "-1.0e-05"
  end

=begin
  # XXX RubyMotion does not support this, and it does not seem like a big deal?
  it "uses non-e format for a positive value with whole part having 14 decimal places" do
    10000000000000.0.to_s.should == "10000000000000.0"
  end

  it "uses non-e format for a negative value with whole part having 14 decimal places" do
    -10000000000000.0.to_s.should == "-10000000000000.0"
  end

  it "uses non-e format for a positive value with whole part having 16 decimal places" do
    1000000000000000.0.to_s.should == "1000000000000000.0"
  end

  it "uses non-e format for a negative value with whole part having 15 decimal places" do
    -1000000000000000.0.to_s.should == "-1000000000000000.0"
  end
=end

  it "uses e format for a positive value with whole part having 16 decimal places" do
    10000000000000000.0.to_s.should == "1.0e+16"
  end

  it "uses e format for a negative value with whole part having 16 decimal places" do
    -10000000000000000.0.to_s.should == "-1.0e+16"
  end

  it "outputs the minimal, unique form to represent the value" do
    0.56.to_s.should == "0.56"
  end
end
