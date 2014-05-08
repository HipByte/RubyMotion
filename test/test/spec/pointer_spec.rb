describe "Pointer" do
  it "can point to C strings" do
    vals = (1..10).to_a
    ptr = Pointer.new(:string, vals.size)
    vals.each_with_index { |v, i| ptr[i] = v.to_s }
    TestMethod.testPointerToStrings(ptr, length:vals.size).should == vals.inject(0) { |m, v| m + v } 
  end
end

describe "Void-pointers" do
  it "does not try to convert an object" do
    obj = Object.new
    TestVoidPointer.methodWithObjectVoidPointer(obj).should == obj
  end

  it "does convert a Pointer to the actual data" do
    pointer = Pointer.new('i')
    pointer[0] = 42
    TestVoidPointer.methodWithCTypeVoidPointer(pointer).should == 42
  end
end
