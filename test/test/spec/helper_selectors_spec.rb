describe "Objective-C setter" do
  it "is available in its Ruby `#setter=` form" do
    TestHelperSelectors.new.should.respond_to :aSetter=
  end

  it "is callable in its Ruby `#setter=` form" do
    obj = TestHelperSelectors.new
    obj.aSetter = 42
    obj.aSetter.should == 42
  end
end

describe "Objective-C predicate" do
  it "is available in its Ruby `#predicate?` form" do
    TestHelperSelectors.new.should.respond_to :predicate?
  end

  it "is callable in its Ruby `#predicate?` form" do
    obj = TestHelperSelectors.new
    obj.aSetter = 42
    obj.predicate?(42).should == true
  end
end

describe "Objective-C subscripting" do
  broken_on_32bit_it "is available in its Ruby `#[]` getter form" do
    obj = TestHelperSelectors.new
    obj.should.respond_to :[]
  end

  broken_on_32bit_it "is available in its Ruby `#[]=` setter form" do
    obj = TestHelperSelectors.new
    obj.should.respond_to :[]=
  end

  broken_on_32bit_it "works with indexed-subscripting" do
    obj = TestHelperSelectors.new
    o = obj[0] = 42
    obj[0].should == 42
    o.should == 42
  end

  broken_on_32bit_it "works with keyed-subscripting" do
    obj = TestHelperSelectors.new
    o = obj['a'] = 'foo'
    obj['a'].should == 'foo'
    o.should == 'foo'
  end
end

class TestHelperSelectors
  attr_accessor :validation_handler

  def validatePropertyForKVCValidation(value, error:error)
    @validation_handler.call(value, error)
  end

  def valid?(errorPointer = nil)
    __validate__(errorPointer || Pointer.new('@'))
  end
  alias_method :validate!, :valid?
end

describe "KVC (and Core Data) property validation" do
  before do
    @obj = TestHelperSelectors.new
    @obj.propertyForKVCValidation = 42
  end

  it "boxes the arguments in Pointer objects" do
    yielded_value = yielded_error = nil
    @obj.validation_handler = lambda do |value, error|
      yielded_value, yielded_error = value, error
      true
    end
    @obj.validate!

    yielded_value.should.be.instance_of Pointer
    yielded_value[0].should == 42
    yielded_error.should.be.instance_of Pointer
    yielded_error[0].should == nil
  end

  it "can pass validation" do
    @obj.validation_handler = lambda { |value, _| value[0] == 42 }
    @obj.should.be.valid

    @obj.propertyForKVCValidation = 21
    @obj.should.not.be.valid
  end

  it "can modify the value and error" do
    expected_value = 21
    expected_error = NSError.errorWithDomain('com.hipbyte.rubymotion.test', code:42, userInfo:nil)

    @obj.validation_handler = lambda do |value, error|
      value[0] = expected_value
      error[0] = expected_error
      false
    end
    errorPointer = Pointer.new('@')
    errorPointer[0] = nil
    @obj.validate!(errorPointer)

    @obj.propertyForKVCValidation.should == expected_value
    errorPointer[0].should == expected_error
  end
end
