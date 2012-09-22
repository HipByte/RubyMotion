describe "Pointer" do
  it "can point to C strings" do
    vals = (1..10).to_a
    ptr = Pointer.new(:string, vals.size)
    vals.each_with_index { |v, i| ptr[i] = v.to_s }
    TestMethod.testPointerToStrings(ptr, length:vals.size).should == vals.inject(0) { |m, v| m + v } 
  end
end
