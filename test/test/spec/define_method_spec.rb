class TestDefineMethod
  define_method :test1 { 42 }
  define_method :test2 { |x| x + 100 }
  define_method :test3 { |x, y| x + y }
  define_method :test4 { |*ary| ary.inject(0) { |m, x| m + x } }     
end

describe "define_method" do
  it "defines pure-Ruby methods" do
    obj = TestDefineMethod.new
    obj.test1.should == 42
    obj.test2(42).should == 142
    obj.test3(40, 2).should == 42
    obj.test4(10, 10, 10, 10, 1, 1).should == 42
  end
end

module TestDefineModuleExtendSelfBefore
  define_method :foo { 42 }
  extend self
end

describe "define_method" do
  it "defines methods that are copied upon before module inclusion" do
    TestDefineModuleExtendSelfBefore.foo.should == 42
  end
end

module TestDefineModuleExtendSelfAfter
  extend self
  define_method :foo { 42 }
end

describe "define_method" do
  it "defines methods that are copied upon after module inclusion" do
    TestDefineModuleExtendSelfAfter.foo.should == 42
  end
end

module TestDefineMethodAlias
  define_method :test { 42 }
  alias_method :test2, :test
end

describe "define_method" do
  it "defines methods that are copied upon aliasing" do
    obj = TestDefineMethodAlias.new
    obj.test.should == 42
    obj.test2.should == 42
  end
end

class TestIncludedModule
  include TestDefineMethodAlias
  include TestDefineModuleExtendSelfBefore
end

class TestIncludedModule2
  include TestDefineMethodAlias
end

class TestInheritedClass < TestIncludedModule2
end

class TestExtendedClass
  extend TestDefineMethodAlias
end

describe "define_method" do
  # RM-37 Assertion failed when trying to define a method on a module
  it "should work on class which included module" do
    obj = TestIncludedModule.new
    obj.test.should == 42
    obj.test2.should == 42
    obj.foo.should == 42
  end

  # RM-104 Assertion failed where inherits a class which includes a module which contains define_method
  it "should work on class which inherits class" do
    obj = TestInheritedClass.new
    obj.test.should == 42
  end

  # RM-105 Assertion failed where extend a module which contains define_method
  it "should work on extended class" do
    TestExtendedClass.test.should == 42
  end
end
