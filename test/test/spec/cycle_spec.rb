describe "cycles" do
  class TestObjectCycle
    def test_block_retain
      test_block_assign { 42 }
    end
    def test_block_assign(&b)
      @b = b
    end
    def test_array_retain
      @a = []
      @a << self
    end
    def test_hash_key_retain
      @h = {}
      @h[self] = 42
    end
    def test_hash_value_retain
      @h = {}
      @h[42] = self
    end
    def test_hash_ifnone_retain
      @h = Hash.new do |h,k| h[k] = [] end
      @h[42] << 42
    end
    def dealloc
      $test_dealloc = true
      super
    end
  end
  xit "created by Proc->self are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_block_retain }
    $test_dealloc.should == true

    # not use autorelease_pool{}
    $test_dealloc = false
    TestObjectCycle.new.test_block_retain
    wait(0.1) { $test_dealloc.should == true }
  end

  it "created by Array are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_array_retain }
    $test_dealloc.should == true
  end

  it "created by Hash keys are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_hash_key_retain }
    $test_dealloc.should == true
  end

  it "created by Hash values are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_hash_value_retain }
    $test_dealloc.should == true
  end

  it "created by Hash->ifnone are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_hash_ifnone_retain }
    $test_dealloc.should == true
  end

  class TestObjectCircle
    attr_accessor :ref
    def dealloc
      $test_dealloc[object_id] = true
      super
    end
  end
 it "created by 2 objects are solved when they are the only thing retaining each other" do
    $test_dealloc = {}
    obj1id = obj2id = nil
    autorelease_pool do
      obj1 = TestObjectCircle.new
      obj2 = TestObjectCircle.new
      obj1id = obj1.object_id
      obj2id = obj2.object_id
      obj1.ref = obj2
      obj2.ref = obj1
    end
    $test_dealloc[obj1id].should == true
    $test_dealloc[obj2id].should == true
  end

  it "created by 2 objects are not solved if retained by something other than each other" do
    $test_dealloc = {}
    obj1id = obj2id = nil
    autorelease_pool do; autorelease_pool do
      @obj1 = TestObjectCircle.new
      obj2 = TestObjectCircle.new
      obj1id = @obj1.object_id
      obj2id = obj2.object_id
      @obj1.ref = obj2
      obj2.ref = @obj1
    end; end
    # obj1 is retained by the spec context. obj2 is retained by obj1
    $test_dealloc[obj1id].should == nil
    $test_dealloc[obj2id].should == nil
    @obj1.inspect.should != nil # no crash
  end

=begin
  # XXX at this point the cycle detector doesn't work outside the autorelease pool where
  # the objects were created, so this spec fails.

  it "created by 2 objects are not solved if retained by something other than each other, but then later that other retain is broken" do
    $test_dealloc = {}
    obj1id = obj2id = nil
    autorelease_pool do
      @obj1 = TestObjectCircle.new
      obj2 = TestObjectCircle.new
      obj1id = @obj1.object_id
      obj2id = obj2.object_id
      @obj1.ref = obj2
      obj2.ref = @obj1
      end
    # obj1 is retained by the spec context. obj2 is retained by obj1
    autorelease_pool do
      @obj1 = nil
    end
    # obj1 is release, now the whole object graph is orphaned and should be cleaned up
    $test_dealloc[obj1id].should == true
    $test_dealloc[obj2id].should == true
  end
=end

  class TestDeallocViewController < UIViewController
    attr_accessor :mode
    def viewDidLoad
      super
      foo {}
    end
    def foo(&b)
      @b = b
    end
    def dealloc
      $test_dealloc = true
      super
    end
  end
  it "created on a view controller by a Proc are solved" do
    $test_dealloc = false
    autorelease_pool do
      x = TestDeallocViewController.alloc.init
      x.view
    end
    $test_dealloc.should == true
  end

  def test_cycle 
    autorelease_pool do
      10.times { TestObjectCycle.new }
    end
  end
  it "can be resolved in multiple threads" do
    8.times do
      Thread.new { test_cycle }
    end
    sleep 1
    42.should == 42 # nocrash
  end
end
