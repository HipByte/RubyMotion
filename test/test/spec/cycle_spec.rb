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
    def test_hash_retain
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
  it "created by Proc->self are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_block_retain }
    $test_dealloc.should == true
  end

  it "created by Array are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_array_retain }
    $test_dealloc.should == true
  end

  it "created by Hash are solved" do
    $test_dealloc = false
    autorelease_pool { TestObjectCycle.new.test_hash_retain }
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
  it "created by 2 objects are solved" do
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
    42.should == 42 # nocrash
  end
end
