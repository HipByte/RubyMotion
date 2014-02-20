describe "NSDate" do
  it "#timeIntervalSinceReferenceDate should work" do
    date = Time.at(-5000000000)
    date.timeIntervalSinceReferenceDate.should == -5978307200

    date = NSDate.alloc.initWithTimeIntervalSince1970(-5000000000)
    date.timeIntervalSinceReferenceDate.should == -5978307200
  end

  it "#initWithTimeIntervalSinceReferenceDate: should work" do
    date = NSDate.alloc.initWithTimeIntervalSinceReferenceDate(-5978307200)
    date.should == Time.at(-5000000000)
  end

  it ".distantFuture should return future time" do
    date = NSDate.distantFuture
    date.utc.to_i.should == (63113904000 + 978307200)
  end

  it ".distantPast should return past time" do
    date = NSDate.distantPast
    date.utc.to_i.should == (-63114076800 + 978307200)
  end
end

