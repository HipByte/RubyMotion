describe "Symbols" do
  it "are based on com.rubymotion.Symbol" do
    :foo.class.should == Symbol
    :foo.class.getName.should == 'com.rubymotion.Symbol'
  end

  it "can be passed to Java methods expecting a java.lang.CharSequence" do
    str_builder = Java::Lang::StringBuilder.new
    str_builder.append(:hello)
    str_builder.append(:world)
    str_builder.toString.should == 'helloworld'
  end
end
