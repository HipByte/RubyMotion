# RM-233 NSDate RangeError / year 2038 problem
describe "Time" do
  it "should handle year 2038 problem" do
    date = Time.at(-5000000000)
    date.to_i.should == -5000000000
    (date - date.utc_offset).strftime("%Y-%m-%d %H:%M:%S").should == "1811-07-23 15:06:40"

    date = Time.at(5000000000)
    date.to_i.should == 5000000000
    (date - date.utc_offset).strftime("%Y-%m-%d %H:%M:%S").should == "2128-06-11 08:53:20"
  end
end

describe "NSDate" do
  it "should handle year 2038 problem" do
    date = NSDate.alloc.initWithTimeIntervalSince1970(-5000000000)
    date.to_i.should == -5000000000
    (date - date.utc_offset).strftime("%Y-%m-%d %H:%M:%S").should == "1811-07-23 15:06:40"

    date = NSDate.alloc.initWithTimeIntervalSince1970(5000000000)
    date.to_i.should == 5000000000
    (date - date.utc_offset).strftime("%Y-%m-%d %H:%M:%S").should == "2128-06-11 08:53:20"
  end
end
