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

describe "String#<< with a codepoint" do
  it "works on ASCII/BINARY strings" do
    s = ""
    s.encoding.should == Encoding::UTF_8
    s << 3
    s.should == "\x03"

    s.force_encoding 'ASCII-8BIT'
    s.encoding.should == Encoding::ASCII_8BIT
    s << 3
    s.should == "\x03\x03"

    s.force_encoding 'US-ASCII'
    s.encoding.should == Encoding::ASCII
    s << 3
    s.should == "\x03\x03\x03"
  end
end
