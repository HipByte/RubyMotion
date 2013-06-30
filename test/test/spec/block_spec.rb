def test_block_dvars_proc
  x = '123'
  Proc.new { x + '456' }
end

describe "block dvars" do
  it "are retained when the block is transformed into a Proc" do
    test_block_dvars_proc.call.should == '123456' 
  end

  it "change the store of related lvars" do
    x = '123'
    Proc.new { x += '456' }.call
    x.should == '123456'
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
