describe "Subscripting" do
  broken_on_32bit_it "#respond_to?(:[])" do
    obj = TestSubscripting.new
    obj.respond_to?(:[]).should == true
  end

  broken_on_32bit_it "#respond_to?(:[]=)" do
    obj = TestSubscripting.new
    obj.respond_to?(:[]=).should == true
  end

  broken_on_32bit_it "works with indexed-subscripting" do
    obj = TestSubscripting.new
    o = obj[0] = 42
    obj[0].should == 42
    o.should == 42
  end

  broken_on_32bit_it "works with keyed-subscripting" do
    obj = TestSubscripting.new
    o = obj['a'] = 'foo'
    obj['a'].should == 'foo'
    o.should == 'foo'
  end
end
