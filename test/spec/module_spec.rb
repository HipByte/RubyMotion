class TestModuleSubclass < Module
  def initialize
    @foo = 42
  end
  def foo
    @foo
  end
end

=begin
describe "Module" do
  it "can be subclassed and mixed up" do
    m = TestModuleSubclass.new
    m.foo.should == 42
    o = Object.new
    o.extend(m)
    o.foo.should == 42
  end
end
=end
