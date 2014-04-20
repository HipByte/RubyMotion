class Core_Float_EqualValue_Mock1 < Java::Lang::Object
  def ==(obj)
    2.0 == obj
  end
end

describe "Float#==" do
  it "returns true if self has the same value as other" do
    (1.0 == 1).should == true
    (2.71828 == 1.428).should == false
    (-4.2 == 4.2).should == false
  end

  it "calls 'other == self' if coercion fails" do
    (1.0 == Core_Float_EqualValue_Mock1.new).should == false
    (2.0 == Core_Float_EqualValue_Mock1.new).should == true
  end
end
