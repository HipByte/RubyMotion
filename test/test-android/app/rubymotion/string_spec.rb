describe "Strings" do
  it "are based on com.rubymotion.String" do
    'foo'.class.should == String
    'foo'.class.getName.should == 'com.rubymotion.String'
  end

  it "can be passed to Java methods expecting a java.lang.CharSequence" do
    str_builder = Java::Lang::StringBuilder.new
    str_builder.append('hello')
    str_builder.append(' world')
    str_builder.toString.should == 'hello world'
  end
end
