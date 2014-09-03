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

describe "Module" do
  module BaseModule
    def testMethod1(obj)
      super
    end
    def testMethod2(obj)
      super
    end
  end

  class TestRM583 < TestModuleInclude
    include BaseModule
  end

  # RM-583
  it "included module method should be call correctly from Objc" do
    TestRM583.new.run_testMethod2.should == 456
    TestRM583.new.run_testMethod1.should == 123
  end
end
