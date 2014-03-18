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
  broken_on_32bit_it "is available in its Ruby `#predicate?` form" do
    TestHelperSelectors.new.should.respond_to :predicate?
  end

  broken_on_32bit_it "is callable in its Ruby `#predicate?` form" do
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

