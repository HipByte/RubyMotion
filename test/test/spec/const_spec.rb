describe "iOS constants" do
  it "have their values retrieved at demand" do
    ABAddressBookCreate()
    KABPersonFirstNameProperty.should != KABPersonLastNameProperty
  end
end

describe "kCFBooleanTrue" do
  it "can be retrieved" do
    KCFBooleanTrue.should == true
  end
end

describe "Constants starting with a lower-case character" do
  it "can be retrieved when renamed with a upper-case character" do
    LowerCaseConstant.should == 42
  end
end

describe "#define foo @\"value\" constants (NSString)" do
  it "can be retrieved" do
    TestNSStringConstant.should == 'foo'
  end
end

describe "#define foo \"value\" constants (C string)" do
  it "can be retrieved" do
    TestStringConstant.should == 'foo'
  end
end
