describe "Literal integers" do
  it "are based on java.lang.Long" do
    Fixnum.should == Java::Lang::Long
    123.class.should == Java::Lang::Long
  end
end

describe "Literal floats" do
  it "are based on java.lang.Double" do
    Float.should == Java::Lang::Double
    (3.14).class.should == Java::Lang::Double
  end
end

describe "Literal bignums" do
  it "are based on java.math.BigInteger" do
    Bignum.should == Java::Math::BigInteger
    29183721937129837219307219837219387213982173982173982173981273912732198371.class.should == Java::Math::BigInteger
  end
end
