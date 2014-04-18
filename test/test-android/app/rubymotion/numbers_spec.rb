describe "Literal integers" do
  it "are based on java.lang.Integer" do
    Fixnum.should == Java::Lang::Integer
    123.class.should == Java::Lang::Integer
  end
end

describe "Literal floats" do
  it "are based on java.lang.Float" do
    Float.should == Java::Lang::Float
    (3.14).class.should == Java::Lang::Float
  end
end

describe "Literal bignums" do
  it "are based on java.math.BigInteger" do
    Bignum.should == Java::Math::BigInteger
    29183721937129837219307219837219387213982173982173982173981273912732198371.class.should == Java::Math::BigInteger
  end
end
