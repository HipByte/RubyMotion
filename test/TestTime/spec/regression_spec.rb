# RM-253
describe "Time" do
  it "#== should be equal to duplicated object" do
    date = Time.now
    date.copy.should == date
    date.should == date.copy

    date.dup.should == date
    date.should == date.dup
  end

  it "#eql? should be equal to duplicated object" do
    date = Time.now
    date.copy.eql?(date).should == true
    date.eql?(date.copy).should == true

    date.dup.eql?(date).should == true
    date.eql?(date.dup).should == true

  end
end

#RM-337
describe "Time#hash" do
  class Time
    def to_nsdate
      NSDate.dateWithTimeIntervalSince1970(self.to_i)
    end
  end

  it "should be equal after converting NSDate to Time" do
    a = Time.now
    a.to_nsdate.hash.should == a.to_nsdate.hash
  end
end