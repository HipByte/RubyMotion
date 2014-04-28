class TestShortcut
  attr_reader :foo

  def setFoo(x)
    @foo = x
  end
end

describe "Shortcut method on RubyObject" do
  it "should work" do
    # RM-455
    obj = TestShortcut.new
    obj.respond_to?(:foo=).should == true
    obj.foo = 42
    obj.foo.should == 42
  end
end