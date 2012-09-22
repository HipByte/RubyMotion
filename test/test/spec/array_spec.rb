describe "Array#delete_at" do
  it "does not prematurely release the removed object" do
    a = ['a', 'b', 'c']
    o = a[1]
    a.delete_at(1)
    o.should == 'b'
    a.should == ['a', 'c']
    a.insert(1, o)
    o.should == 'b'
    a.should == ['a', 'b', 'c']
  end
end

describe "Array#shift" do
  it "should not prematurely release the removed object" do
    @a = nil
    RunloopYield.new do
      @a = ['a', 'b', 'c'].shift
    end
    @a.should == 'a'
  end
end
