describe "Symbols" do
  it "are based on com.rubymotion.Symbol" do
    :foo.class.should == Symbol
    :foo.class.inspect.should == 'com.rubymotion.Symbol'
  end
end

