class BlockTestParam
  def dealloc
    $dealloc_test = true
    super
  end
  def res
    42
  end
end

class BlockTest
  def test_sync
    o = BlockTestParam.new
    1.times do
      @res = o.res
    end
  end

  def test_async
    o = BlockTestParam.new
    Dispatch::Queue.concurrent.async do
      @res = o.res
    end
  end
  def res
    @res
  end
end

describe "&block dvars" do
  it "are properly retain/released (sync)" do
    $dealloc_test = false
    o = BlockTest.new
    o.performSelectorOnMainThread(:'test_sync', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    o.res.should == 42
    $dealloc_test.should == true
  end

  it "are properly retain/released (async)" do
    $dealloc_test = false
    o = BlockTest.new
    o.performSelectorOnMainThread(:'test_async', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    o.res.should == 42
    $dealloc_test.should == true
  end
end

class DeallocTest
  def initTest(*args)
    init

    1 + 2
    "test"
    self
  end

  def self.test
    DeallocTest.new
  end
  def self.test_expression
    obj = DeallocTest.alloc
    obj.send('init')
  end
  def self.test_nested_init
    obj = DeallocTest.alloc.initTest("test")
  end

  def dealloc
    super
    $dealloc_test = true
  end
end

class DeallocTest2 < NSURL
  def initialize(*args)
    initWithString('')
    1 + 2
    "test"
  end

  def self.test_nested_initialize
    obj = DeallocTest2.new("test")
  end

  def dealloc
    super
    $dealloc_test = true
  end
end

describe "dealloc" do
  before do
    $dealloc_test = false
  end

  it "can be defined and is called" do
    DeallocTest.performSelectorOnMainThread(:'test', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    $dealloc_test.should == true
  end

  it "should work if the expression is invoked before initialized" do
    DeallocTest.performSelectorOnMainThread(:'test_expression', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    $dealloc_test.should == true
  end

  it "should work with nested #initXXX" do
    DeallocTest.performSelectorOnMainThread(:'test_nested_init', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    $dealloc_test.should == true
  end

  xit "should work with nested initialize" do
    DeallocTest2.performSelectorOnMainThread(:'test_nested_initialize', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    $dealloc_test.should == true
  end

end

$retain_test = false
class RetainTest
  def retain
    super
    $retain_test = true
  end
end

describe "retain and release" do
  it "can be called directly" do
    o = Object.new
    o.retainCount.should == 1
    o.retain
    o.retainCount.should == 2
    o.release
    o.retainCount.should == 1
  end

  it "can be defined" do
    o = RetainTest.new
    $retain_test.should == false
    NSArray.arrayWithObject(o)
    $retain_test.should == true
  end
end

describe "references" do
  it "can be created using instance variables" do
    o = Object.new
    o.retainCount.should == 1
    @tmpref = o
    o.retainCount.should == 2
    autorelease_pool { @tmpref = nil }
    o.retainCount.should == 1
  end

  it "can be created using constants" do
    o = Object.new
    o.retainCount.should == 1
    ConstRef = o
    o.retainCount.should == 2
  end
end

class InitTest
  def self.test_start
    @o = InitTest.new
    @o.instance_variable_set(:@foo, 42)
    5.times { @o.init }
  end
  def self.test_res
    @o
  end
end

describe "init" do
  it "can safely be called separately" do
    InitTest.performSelectorOnMainThread(:'test_start', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    InitTest.test_res.instance_variable_get(:@foo).should == 42
  end
end

class InitSuperTest
  def init
    if super
    end
    self
  end
  def dealloc
    $dealloc_test = true
    super
  end
  def self.test_start
    InitSuperTest.alloc.init
    nil
  end
end

describe "init+super" do
  it "returns an autoreleased object" do
    $dealloc_test = false
    InitSuperTest.performSelectorOnMainThread(:'test_start', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
    $dealloc_test.should == true
  end
end

class Proc
  # The block should return the object that is supposed to be autoreleased.
  def autoreleased?
    object = count_in_autorelease_pool = nil
    autorelease_pool do
      object = self.call
      raise 'Unexpected `nil` value' if object.nil?
      object.retain
      count_in_autorelease_pool = object.retainCount
    end
    result = (object.retainCount == count_in_autorelease_pool - 1)
    object.release
    result
  end
end

describe "C functions that return retained objects" do
  # TODO
  it "returns an autoreleased object if the function name contains 'Create'", :unless => osx_32bit? do
    lambda {
      CFStringCreateWithFormat(nil, {}, '%@', 42)
    }.should.be.autoreleased
  end

  it "returns an autoreleased object if the function name contains 'Copy'" do
    lambda {
      CFURLCopyPath(NSURL.URLWithString('http://example.com/some/path'))
    }.should.be.autoreleased
  end
end

describe "Objective-C methods that return retained objects" do
  # TODO Needed?
  #it "returns an autoreleased object if the method name starts with 'alloc'" do
  #end

  it "returns an autoreleased object if the method name starts exactly with 'new'" do
    lambda { TestMethod.newRetainedInstance }.should.be.autoreleased
    lambda { TestMethod.newbuildRetainedInstance }.should.not.be.autoreleased
  end

  it "returns an autoreleased object if the method name contains 'copy'" do
    object = TestMethod.new
    lambda { object.copyAndReturnRetainedInstance }.should.be.autoreleased
    lambda { object.retainedCopy }.should.be.autoreleased
    lambda { object.copyingAndReturningRetainedInstance }.should.not.be.autoreleased
  end
end

class RetainCounter
  attr_reader :retain_count

  def initialize
    @retain_count = 0
  end

  def retain
    @retain_count += 1
    super
  end
end

describe "Ruby methods that return retained objects" do
  def newObject; Object.new; end
  def newbuildObject; Object.new; end

  def newRetainCounter; RetainCounter.new; end
  def newbuildRetainCounter; RetainCounter.new; end

  it "returns an unretained autoreleased object if the method starts with 'new' and is called from Ruby" do
    lambda { newRetainCounter }.should.be.autoreleased
    lambda { newbuildRetainCounter }.should.be.autoreleased
    newRetainCounter.retain_count.should == 0
    newbuildRetainCounter.retain_count.should == 0
  end

  it "returns a retained object if the method name starts exactly with 'new' and is called from Objective-C" do
    TestMethod.isReturnValueRetained(self, forSelector:'newRetainCounter').should == true
    TestMethod.isReturnValueRetained(self, forSelector:'newbuildRetainCounter').should == false
  end

  def copyObject; Object.new; end
  def objectCopy; Object.new; end
  def copyingObject; Object.new; end

  def copyRetainCounter; RetainCounter.new; end
  def retainCounterCopy; RetainCounter.new; end
  def copyingRetainCounter; RetainCounter.new; end

  it "returns an unretained autoreleased object if the method name contains 'copy' and is called from Ruby" do
    lambda { copyObject }.should.be.autoreleased
    lambda { objectCopy }.should.be.autoreleased
    lambda { copyingObject }.should.be.autoreleased
    copyRetainCounter.retain_count.should == 0
    retainCounterCopy.retain_count.should == 0
    copyingRetainCounter.retain_count.should == 0
  end

  it "returns a retained object if the method name contains 'copy' and is called from Objective-C" do
    TestMethod.isReturnValueRetained(self, forSelector:'copyRetainCounter').should == true
    TestMethod.isReturnValueRetained(self, forSelector:'retainCounterCopy').should == true
    TestMethod.isReturnValueRetained(self, forSelector:'newbuildRetainCounter').should == false
  end
end

class TestSetValueForKey
  attr_accessor :foo
end

describe "setValue:forKey:" do
  it "retains the value" do
    o = TestSetValueForKey.new
    val = Object.new
    refcount = val.retainCount
    o.setValue(val, forKey:'foo')
    o.foo.should == val
    val.retainCount.should >= refcount + 1
  end
end

describe "setValuesForKeysWithDictionary:" do
  it "retain the values" do
    o = TestSetValueForKey.new
    val = Object.new
    refcount = val.retainCount
    o.setValuesForKeysWithDictionary({'foo' => val})
    val.retainCount.should >= refcount + 1
  end
end

describe "Random" do
  it "can be allocated" do
    autorelease_pool do
      100.times { Random.new }
    end
    1.should == 1
  end
end

describe "NSDate" do
  it "#new should work without malloc_error_break" do
    autorelease_pool do
      100.times { NSDate.new }
    end
    1.should == 1
  end

  it "alloc.init.timeIntervalSince1970 should work without malloc_error_break" do
    autorelease_pool do
      100.times { NSDate.alloc.init.timeIntervalSince1970 }
    end
    1.should == 1
  end
end

describe "NSMutableArray" do
  class NSArray
    alias old_dealloc dealloc

    def dealloc
      $nsarray_dealloc = true
      old_dealloc
    end
  end

  before do
    @ary = NSMutableArray.arrayWithArray([1, 2, 3, 4, 5])
    $nsarray_dealloc = false
  end

  it "#first(n) should return autoreleased object" do
    autorelease_pool do
      ret = @ary.first(2)
    end
    $nsarray_dealloc.should == true
  end

  it "#last(n) should return autoreleased object" do
    autorelease_pool do
      ret = @ary.last(2)
    end
    $nsarray_dealloc.should == true
  end

  it "#pop(n) should return autoreleased object" do
    autorelease_pool do
      ret = @ary.pop(2)
    end
    $nsarray_dealloc.should == true
  end

  it "#shift(n) should return autoreleased object" do
    autorelease_pool do
      ret = @ary.shift(2)
    end
    $nsarray_dealloc.should == true
  end
end

class Range
  def dealloc
    $dealloc_test = true
    super
  end
end
describe "Range" do
  before do
    $dealloc_test = false
  end

  it "#new should return autoreleased objects" do
    autorelease_pool do
      Range.new(10, 20)
    end
    $dealloc_test.should == true
  end

  it "with dot syntax returns autoreleased objects" do
    autorelease_pool do
      (1..2)
    end 
    $dealloc_test.should == true
  end
end

describe "Hash" do
  class TestHash
    def initialize
      @fields = { foo: "foo" }
    end

    def test_hash_aset
      foo = @fields[:foo]
      @fields[:foo] = "bar"

      foo.inspect

      @fields[:foo] = "foo"
    end

    def test_hash_clear
      foo = @fields[:foo]
      @fields.clear

      foo.inspect

      @fields[:foo] = "foo"
    end

    def test_hash_removeObjectForKey
      foo = @fields[:foo]
      @fields.removeObjectForKey(:foo)

      foo.inspect

      @fields[:foo] = "foo"
    end
  end

  # RM-350
  it "#[]= should not release the object" do
    @foo = TestHash.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_hash_aset', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_hash_aset should not cause a crash
    1.should == 1
  end

  # RM-351
  it "#clear should not release the object" do
    @foo = TestHash.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_hash_clear', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_hash_clear should not cause a crash
    1.should == 1
  end

  # RM-352
  it "#removeObjectForKey should not release the object" do
    @foo = TestHash.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_hash_removeObjectForKey', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_hash_removeObjectForKey should not cause a crash
    1.should == 1
  end
end

describe "Array" do
  class TestArray
    def initialize
      @array = ["a", "b", "c"]
    end

    def test_array_delete
      obj = @array[0]
      @array.delete("a")

      obj.inspect

      @array.unshift("a")
    end

    def test_clear
      obj = @array[0]
      @array.clear

      obj.inspect

      @array = ["a", "b", "c"]
    end

  end

  # RM-354
  it "#delete should not release the object" do
    @foo = TestArray.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_array_delete', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_array_delete should not cause a crash
    1.should == 1
  end

  # RM-368
  it "#clear should not release the object" do
    @foo = TestArray.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_clear', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_clear should not cause a crash
    1.should == 1
  end
end

describe "Struct" do
  class TestStruct
    def initialize
      st = Struct.new("Cat", :name, :state)
      @cat = st.new("foo", "sleep")
    end

    def test_struct_aset
      name = @cat.name
      @cat[:name] = "foo"

      name.inspect

      state = @cat.state
      @cat[1] = "sleep"

      state.inspect
    end

    def test_struct_setter
      name = @cat.name
      @cat.name = "foo"

      name.inspect
    end
  end

  # RM-355
  xit "#[]= should not released the object" do
    @foo = TestStruct.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_struct_aset', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_struct_aset should not cause a crash
    1.should == 1
  end

  # RM-356
  xit "setter method should not released the object" do
    @foo = TestStruct.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_struct_setter', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_struct_setter should not cause a crash
    1.should == 1
  end
end

describe "Boxed" do
  class TestBoxed
    def initialize
      @member = MyStructHasName.new
      @member.name = "foo"
    end

    def test_boxed_setter
      name = @member.name
      @member.name = "foo"

      name.inspect
    end
  end

  # RM-358
  it "setter method should not released the object" do
    @foo = TestBoxed.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_boxed_setter', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_boxed_setter should not cause a crash
    1.should == 1
  end
end

describe "Kernel" do
  class TestKernelOther
    def initialize
      @name = "bar"
    end
  end

  class TestKernel
    def initialize
      @bar = TestKernelOther.new
    end

    def test_ivar_set
      name = @bar.instance_variable_get(:@name)
      @bar.instance_variable_set(:@name, "bar")

      name.inspect
    end
  end

  # RM-359
  it "#instance_variable_set method should not released the object" do
    @foo = TestKernel.new

    5.times do 
      @foo.performSelectorOnMainThread(:'test_ivar_set', withObject:nil, waitUntilDone:false)
      NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
    end

    # test_ivar_set should not cause a crash
    1.should == 1
  end
end

# RM-290
describe "NSMutableData" do
  class NSMutableData
    alias old_dealloc dealloc

    def dealloc
      $nsmutabledata_dealloc = true
      old_dealloc
    end
  end

  xit "#initWithLength return autoreleased objects" do
    $nsmutabledata_dealloc = false
    autorelease_pool do
      data = NSMutableData.alloc.initWithLength(100)
    end
    $nsmutabledata_dealloc.should == true
  end
end
