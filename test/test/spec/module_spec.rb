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
      obj.should == true
      super
    end
    def testMethod2(obj)
      obj.should == true
      super
    end
  end

  module BaseModule2
    def testMethod1(obj)
      $module2_method_called = true
      super
    end
    def testMethod2(obj)
      $module2_method_called = true
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

  class TestRM601 < TestModuleInclude
    include BaseModule, BaseModule2
  end

  # RM-601
  it "included module methods should be call correctly from Objc if included some module" do
    $module2_method_called = false
    TestRM601.new.run_testMethod2.should == 456
    $module2_method_called.should == true

    $module2_method_called = false
    TestRM601.new.run_testMethod1.should == 123
    $module2_method_called.should == true
  end
end
