describe "Strings containing null terminators" do
  it "can be compiled and used" do
    s = "\x00"
    s.size.should == 1
    s = "\x00\x00"
    s.size.should == 2
    s = "\x00\x00\x00"
    s.size.should == 3
  end
end
