describe "BOOL Type Encoding" do
  it "should be converted when a method has BOOL pointer" do
    # RM-468
    ptr = Pointer.new(:bool)
    ptr.assign(true)
    obj = TestBoolType.alloc.initWithBoolPtr(ptr)
    obj.value.should == true

    ptr.assign(false)
    obj = TestBoolType.alloc.initWithBoolPtr(ptr)
    obj.value.should == false
  end

  it "should be converted when a structure name has 'c' characters" do
    # RM-457
    obj = MyStructHasBool.new
    obj.bool_value = true
    obj = TestBoolType.alloc.initWithStruct(obj)
    obj.value.should == true

    obj = MyUnionHasBool.new
    obj.st.bool_value = true
    obj = TestBoolType.alloc.initWithUnion(obj)
    obj.value.should == true
  end

  it "should be converted when BOOL is contained in return value" do
    obj = TestBoolType.alloc.init
    obj.returnBool.should == true
  end
end

