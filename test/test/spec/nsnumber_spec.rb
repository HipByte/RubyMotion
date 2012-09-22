describe "Bignums" do
  it "can be converted into NSNumber with 'long long' type" do
    num = 1346543403000
    NSNumber.numberWithLongLong(num).longLongValue.should == num
  end
end
