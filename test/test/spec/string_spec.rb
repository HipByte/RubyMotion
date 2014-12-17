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

# TODO should be part of RubySpec
describe "Strings with multibyte characters" do
  it "finds the index of a character" do
    "..€€……".index(".").should == 0
    "..€€……".index("€").should == 2
    "..€€……".index("…").should == 4
  end

  # TODO
  xit "finds the most right-side index of a character" do
    "..€€……".rindex(".").should == 1
    "..€€……".rindex("€").should == 3
    "..€€……".rindex("…").should == 5
  end
end

# RM-528
describe "String#getCharacters:range:" do
  def get_characters(loc, len)
    buf_str = Pointer.new(:ushort, len)
    buf_nsstr = Pointer.new(:ushort, len)

    @str.getCharacters(buf_str, range:NSMakeRange(loc, len))
    @nsstr.getCharacters(buf_nsstr, range:NSMakeRange(loc, len))

    len.times do |i|
      buf_str[i].should == buf_nsstr[i]
    end
  end

  it " should extract Unicode properly" do
    @str = "😄😃😀😊☺️😉😍😘😚😗😙😜😝😛"
    @nsstr = NSString.stringWithString(@str)

    @str.length.times do |i|
      get_characters(i, @str.length - i)
    end
  end
end

# RM-684
describe "NSString#initWithXXX" do
  it "should not causes a crash even if NSTaggedPointerString is created" do
    data = "Hello".dataUsingEncoding(NSUTF8StringEncoding)
    string = NSString.alloc.initWithData(data, encoding:NSUTF8StringEncoding)
    string.should == "Hello"
  end
end

