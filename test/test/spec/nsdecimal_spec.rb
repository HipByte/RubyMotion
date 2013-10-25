describe "NSDecimal" do
  xit "can be created from NSDecimalNumber" do
    dn = NSDecimalNumber.decimalNumberWithString('123.456')
    d = dn.decimalValue
    d.class.should == NSDecimal
    NSDecimalNumber.decimalNumberWithDecimal(d).should == dn
    ptr = Pointer.new(NSDecimal.type)
    ptr[0] = d
    NSDecimalString(ptr, nil).should == dn.stringValue
  end
end
