class MyTestMethod < TestMethod
  def methodReturningCGSize
    super
  end
  def methodReturningCGRect
    super
  end
end

describe 'A method accepting a 32-bit struct' do
  # TODO
  it "can be called", :unless => bits == 64 do
    s = MyStruct4C.new(1, 2, 3, 4)
    TestMethod.testMethodAcceptingMyStruct4C(s).should == true
    TestMethod.testMethodAcceptingMyStruct4C(s, another:s).should == true
  end
end

describe "A method returning a big 32-bit integer" do
  it "returns a Bignum", :unless => bits == 64 do
    o = TestMethod.new.methodReturningLargeInt
    o.class.should == Bignum
    o.should == 2147483646
  end
end

describe 'A method returning a 64-bit struct' do
  # TODO
  it "can be called", :if => ios? do
    o = TestMethod.new
    o.methodReturningCGSize.should == CGSize.new(1, 2)
  end

  it "can be defined" do
    o = MyTestMethod.new
    TestMethod.testMethodReturningCGSize(o).should == true
  end
end

describe 'A method returning a 128-bit struct' do
  # TODO
  it "can be called", :if => ios? do
    o = TestMethod.new
    o.methodReturningCGRect.should == CGRect.new(CGPoint.new(1, 2), CGSize.new(3, 4))
  end

  it "can be defined" do
    o = MyTestMethod.new
    TestMethod.testMethodReturningCGRect(o).should == true
  end
end

describe 'A 3rd-party method accepting an iOS enum' do
  it "can be called", :if => ios? do
    TestMethod.testMethodAcceptingUIInterfaceOrientation(UIInterfaceOrientationPortrait).should == true
    TestMethod.testMethodAcceptingUIInterfaceOrientation(UIInterfaceOrientationLandscapeLeft).should == false
  end
end

describe 'A method accepting and returning UIEdgeInsets' do
  it "can be called", :if => ios? do
    s = UIEdgeInsetsMake(1, 2, 3, 4)
    TestMethod.testMethodAcceptingUIEdgeInsets(s).should == true
  end
end

describe 'A method accepting a block' do
  it "can be called (1)" do
    TestMethod.testMethodCallingBlock(lambda { 42 }).should == 42
    TestMethod.testMethodCallingBlock(nil).should == 42
  end

  it "can be called (2)" do
    res = []
    [1, 2, 3, 4, 5].enumerateObjectsUsingBlock(lambda do |obj, idx, stop_ptr|
      res << [obj, idx]
    end)
    res.should == [[1,0], [2,1], [3,2], [4,3], [5,4]]
    res = []
    [1, 2, 3, 4, 5].enumerateObjectsUsingBlock(lambda do |obj, idx, stop_ptr|
      res << obj
      stop_ptr[0] = true if idx == 2
    end)
    res.should == [1, 2, 3]
  end 
end

describe 'A method accepting a CF type' do
  it "can be called (1)" do
    s = CFStringCreateCopy(nil, 'foo')
    TestMethod.testMethodAcceptingCFType(s).should == true
    TestMethod.testMethodAcceptingCFType('foo').should == true
  end

  it "can be called (2)", :if => ios? do
    controller = ABPersonViewController.alloc.init
    person = ABPersonCreate()
    controller.displayedPerson = person
    controller.displayedPerson.should == person
  end
end

describe 'A method returning a CF type' do
  it "can be called" do
    s = CFStringCreateCopy(nil, 'foo')
    s.should == 'foo'
  end
end

describe 'CFTypeRefs' do
  it "are mapped as 'id' types" do
    KSecAttrAccount.should == 'acct' # and not Pointer
  end
end


describe "Typedef'ed argument" do
  # RM-518
  it "should be accepted" do
    TestMethod.testTypedefArgument('foo').should == 'foo'
  end
end

describe 'RUBY_ENGINE' do
  it "should be 'rubymotion'" do
    RUBY_ENGINE.should == 'rubymotion'
  end
end

describe "Objects conforming to NSFastEnumeration" do
  it "can be iterated using #each" do
    iter = TestIterator.new
    enum = iter.to_enum
    enum.to_a.should == ['1', '2', '3', '4', '5']
  end
end

class TestAttrAlias
  attr_accessor :foo
  alias :bar :foo
end

describe "attr_" do
  it "can be aliased" do
    o = TestAttrAlias.new
    o.foo = 42
    o.bar.should == 42
  end

  it "return proper values when used by valueForKey:" do
    o = TestAttrAlias.new
    TestMethod.testValueForKey(o, expected:nil).should == true
    o.foo = '42' 
    TestMethod.testValueForKey(o, expected:'42').should == true
  end
end

class TestNewInstance
end

describe "A method sending +new on a Ruby class" do
  it "returns an instance" do
    o = TestMethod.new.methodSendingNew(TestNewInstance)
    o.class.should == TestNewInstance
  end
end

class TestPrivateMethod
  def foo; 42; end
  private
  def bar; 42; end
end

describe "A private method" do
  # TODO
  it "cannot be called with #public_send", :unless => osx_32bit? do
    o = TestPrivateMethod.new
    o.foo.should == 42
    o.send(:foo).should == 42
    o.public_send(:foo).should == 42
    lambda { o.bar }.should.raise(NoMethodError)
    o.send(:bar).should == 42
    lambda { o.public_send(:bar) }.should.raise(NoMethodError)
  end
end

describe "An informal protocol method with BOOL types" do
  it "can be called (1)" do
    o = TestMethod.new
    o.testProtocolFlag = true
    o.testProtocolFlag.should == true
    o.testProtocolFlag = false
    o.testProtocolFlag.should == false
  end

  # TODO Do we know of a Foundation version that works on OS X as well?
  it "can be called (1)", :if => ios? do
    o = UITextField.new
    o.enablesReturnKeyAutomatically = true
    o.enablesReturnKeyAutomatically.should == true
  end
end

describe "Constants starting with a lower-case character" do
  it "can be accessed by upper-casing the first letter" do
    LowerCaseConstant.should == 42
  end
end

describe "Classes starting with a lower-case character" do
  it "can be accessed by upper-casing the first letter" do
    k = NSClassFromString('lowerCaseClass')
    k.should != nil
    LowerCaseClass.should == k
  end
end

describe "Large unsigned ints (Bignum)" do
  it "can be passed as 'unsigned ints'" do
    NSNumber.numberWithUnsignedInt(4294967295).should == 4294967295
  end
end

describe "Properties implemented using forwarders" do
  class << self
    # TODO Not on OS X 10.7. Do we have another?
    if defined?(GKMatchRequest)
      alias_method :with_GKMatchRequest_it, :it
    else
      alias_method :with_GKMatchRequest_it, :xit
    end
  end

  with_GKMatchRequest_it "can be called (1)" do
    mr = GKMatchRequest.alloc.init
    mr.maxPlayers.should >= 0
    mr.maxPlayers = 42
    mr.maxPlayers.should == 42
  end

  with_GKMatchRequest_it "can be called (2)" do
    mr = GKMatchRequest.alloc.init
    mr.inviteMessage.should == nil
    mr.inviteMessage = 'welcome to hell'
    mr.inviteMessage.should == 'welcome to hell'
  end
end

describe "NSNotFound" do
  # RM-491
  it "can be retrieved with method return value" do
    num = NSNumber.numberWithUnsignedInteger(NSNotFound)
    num.unsignedIntegerValue.should == NSNotFound
  end
end

describe "Application singleton subclassing" do
  it "registers the principal class" do
    app = (ios? ? UIApplication : NSApplication).sharedApplication
    app.class.should == ApplicationSubclass
  end
end
