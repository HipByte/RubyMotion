describe "Boxed" do
  it ".type should work with structure which has field of structure pointer" do
    MyStructHasStructPointer.type.should == "{MyStructHasStructPointer=^{MyStruct4C}}"
  end

  it ".to_a should recursively call #to_a on fields of the Boxed type" do
    rect = CGRect.new(CGPoint.new(1, 2), CGSize.new(3, 4))
    rect.to_a.should == [[1.0, 2.0], [3.0, 4.0]]
  end
end
