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

