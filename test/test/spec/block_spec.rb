def test_block_dvars_proc
  x = '123'
  Proc.new { x + '456' }
end

describe "block dvars" do
  it "are retained when the block is transformed into a Proc" do
    test_block_dvars_proc.call.should == '123456' 
  end

  it "change the store of related lvars following the block definition" do
    x = '123'
    lambda { x += '456' }.call
    x.should == '123456'
  end

  it "change the store of related lvars following the block definition even if it's enclosed in another block" do
    x = '123'
    if Object.new # should not optimize
      lambda { x += '456' }.call
    end
    x.should == '123456'
  end

  it "change the store of related lvars before the block definition" do
    x = 1
    again = true
    while true
      x += 1
      1.times { x += 1 }
      should_loop = again
      again = false
      break unless should_loop
    end
    x.should == 5
  end

  def test_lvar_dvar_reassignment
    value = nil
    callbacks = lambda do |value|; value; end
    value = *(callbacks.call('42'))
  end
  it "can be re-assigned a new value after the block definition" do
    autorelease_pool do
      obj = test_lvar_dvar_reassignment
      obj.should == ['42']
    end
  end

  def test_lvar_dvar_masign_reassignment
    value = nil
    callbacks = lambda do |value|; value; end
    value, rest = *(callbacks.call('42'))
  end
  it "can be re-assigned a new value with a multiple-assignment instruction after the block definition" do
    autorelease_pool do
      obj = test_lvar_dvar_masign_reassignment
      obj.should == ['42']
    end
  end

  it "are released after the parent block is dispatched" do
    $test_dealloc = false
    autorelease_pool do
      o = Object.new
      def o.dealloc
        $test_dealloc = true
        super
      end
      1.times do
        o.inspect
      end
    end
    $test_dealloc.should == true
  end

  it "are released after the parent block transformed into Proc is released" do
    $test_dealloc = false
    autorelease_pool do
      o = Object.new
      def o.dealloc
        $test_dealloc = true
        super
      end
      Proc.new { o.inspect }
    end
    $test_dealloc.should == true
  end

  it "can be nested (1)" do
    ary = []
    2.times do |i|
      ary += [i.to_s]
      2.times do |j|
        ary += [j.to_s]
      end
    end
    ary.should == ["0", "0", "1", "1", "0", "1"]
  end

  it "can be nested (2)" do
    x = 1
    1.times do
      x += 1
      x.should == 2
      1.times do
        x += 1
        x.should == 3
        1.times do
          x += 1
          x.should == 4
          1.times do
            x += 1
            x.should == 5
            x += 1
          end
          x.should == 6
          x += 1
        end
        x.should == 7
        x += 1
      end
      x.should == 8
      x += 1
    end 
    x.should == 9
  end

  # http://hipbyte.myjetbrains.com/youtrack/issue/RM-213
  it "are synchronized when a block breaks" do
    foo = '1'
    1.times do |i|
      1.times { |j| }
      foo = '2'
      break
    end
    foo.should == '2'
  end

  def schedule_on_main(*args, &blk)
    cb = proc do
      blk.call(*args)
    end
    ::Dispatch::Queue.main.async &cb
  end
  it "are retained by Dispatch::Queue#async" do
    schedule_on_main(42) {}
    42.should == 42 # no crash
  end

  class TestDefineMethod
    def self.create_foo(o)
      define_method :foo { o }
    end
  end
  it "are retained when the block is transformed into a Method object" do
    autorelease_pool { TestDefineMethod.create_foo('12345') }
    TestDefineMethod.new.foo.should == '12345'
  end
end

# http://hipbyte.myjetbrains.com/youtrack/issue/RM-190
class TestObjectWithConstructorBlock
  def initialize(id, &block)
    @id = id
  end
  def dealloc
    $test_dealloc = true
    super
  end
end
describe "An object accepting block in constructor" do
  it "is properly released (RM-190)" do
    $test_dealloc = false
    autorelease_pool { TestObjectWithConstructorBlock.new(42) { nil } }
    $test_dealloc.should == true
  end
end

# http://hipbyte.myjetbrains.com/youtrack/issue/RM-118
describe "C-level blocks created inside GCD" do
  it "are not prematurely released" do
    autorelease_pool do
      Dispatch::Queue.main.async do
        [1,2,3].enumerateObjectsUsingBlock(lambda do |obj, idx, stop_ptr|
        end)
      end
    end
    sleep 1
    true.should == true # no crash
  end
end

describe "self" do
  class TestSelfRetained
    def test
      lambda { self }
    end
    def test2
      1.times { self }
    end
    def dealloc
      $test_dealloc = true
      super
    end
  end

  it "is retained by the block created within its context" do
    $test_dealloc = false
    autorelease_pool do
      @b = nil
      autorelease_pool { @b = TestSelfRetained.new.test }
      $test_dealloc.should == false
      @b.call.class.should == TestSelfRetained
      @b = nil
    end
    $test_dealloc.should == true
  end

  it "is released when the block is reclaimed" do
    $test_dealloc = false
    autorelease_pool { TestSelfRetained.new.test2 }
    $test_dealloc.should == true
  end
end

describe "Hash.new {}" do
  class TestObjectDealloc
    def dealloc
      $test_dealloc = true
      super
    end
  end
  it "does not leak memory" do
    $test_dealloc = false
    autorelease_pool do
      h = Hash.new { |h, k| h[k] = [] }
      h['1'] << TestObjectDealloc.new
    end
    $test_dealloc.should == true
  end
end
