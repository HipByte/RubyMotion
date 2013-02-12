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
  def self.test
    DeallocTest.new
  end
  def dealloc
    super
    $dealloc_test = true
  end
end

describe "dealloc" do
  it "can be defined and is called" do
    $dealloc_test = false
    DeallocTest.performSelectorOnMainThread(:'test', withObject:nil, waitUntilDone:false)
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
    @tmpref = nil
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

