describe "NSValue objects" do
  it "can be created manually" do
    s = MyStruct4C.new(1, 2, 3, 4)
    pointer = Pointer.new(MyStruct4C.type)
    pointer[0] = s
    val = NSValue.value(pointer, withObjCType:MyStruct4C.type)
    TestMethod.testMethodAcceptingMyStruct4CValue(val).should == true
  end

=begin
  it "can be created from Boxed#to_value" do
    val = MyStruct4C.new(1, 2, 3, 4).to_value
    val.objcType.should == MyStruct4C.type
    TestMethod.testMethodAcceptingMyStruct4CValue(val).should == true
  end
=end
end
