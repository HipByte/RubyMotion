class Core_Fixnum_EqualValue_Mock1 < Java::Lang::Object
  def ==(obj)
    false
  end
end

class Core_Fixnum_EqualValue_Mock2 < Java::Lang::Object
  def ==(obj)
    true
  end
end

describe "Fixnum#==" do
  it "returns true if self has the same value as other" do
    (1 == 1).should == true
    (9 == 5).should == false

    # Actually, these call Float#==, Bignum#== etc.
    (9 == 9.0).should == true
    (9 == 9.01).should == false

    (10 == bignum_value).should == false
  end

  it "calls 'other == self' if the given argument is not a Fixnum" do
    (1 == '*').should == false

    obj = Core_Fixnum_EqualValue_Mock1.new
    1.should_not == obj

    obj = Core_Fixnum_EqualValue_Mock2.new
    2.should == obj
  end
end
