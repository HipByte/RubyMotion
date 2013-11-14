describe "Boxed" do
  it ".type should work with structure which has field of structure pointer" do
    MyStructHasStructPointer.type.should == "{MyStructHasStructPointer=^{MyStruct4C}}"
  end

  it ".to_a should recursively call #to_a on fields of the Boxed type" do
    rect = CGRect.new(CGPoint.new(1, 2), CGSize.new(3, 4))
    rect.to_a.should == [[1.0, 2.0], [3.0, 4.0]]
  end

  it "#==" do
    CGPoint.new(1, 2).should == CGPoint.new(1, 2)
  end

  it "#inspect" do
    CGPoint.new(1, 2).inspect.should == "#<CGPoint x=1.0 y=2.0>"
  end

  it "#to_a" do
    CGPoint.new(1, 2).to_a.should == [1.0, 2.0]
  end

  it "#[]" do
    point = CGPoint.new(1, 2)
    point[0].should == 1.0
    point[1].should == 2.0
  end

  it "#[]=" do
    point = CGPoint.new(1, 2)
    point[0] = 42
    point[0].should == 42
  end

  it "#dup" do
    point = CGPoint.new(1, 2)
    point2 = point.dup
    point.should == point2
  end

  it ".fields" do
    CGPoint.fields.should == [:x, :y]
  end

  it ".opaque?" do
    CGPoint.opaque?.should == false
  end
end
