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

  it "can be nested" do
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
    true.should == true # no crash
  end
end
