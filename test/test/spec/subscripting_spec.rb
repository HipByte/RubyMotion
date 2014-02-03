describe "Subscripting" do
  it "#respond_to?(:[])" do
    obj = TestSubscripting.new
    obj.respond_to?(:[]).should == true
  end

  it "#respond_to?(:[]=)" do
    obj = TestSubscripting.new
    obj.respond_to?(:[]=).should == true
  end

  it "Objective-C literals should work" do
    obj = TestSubscripting.new
    o = obj[0] = 42
    obj[0].should == 42
    o.should == 42

    o = obj['a'] = 'foo'
    obj['a'].should == 'foo'
    o.should == 'foo'
  end
end
