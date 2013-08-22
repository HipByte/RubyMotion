# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/isdst', __FILE__)

# describe "Time#isdst" do
#   it_behaves_like(:time_isdst, :isdst)
# end
describe "Time#isdst" do
  before do
    @method = :isdst
  end

  it "dst? returns whether time is during daylight saving time" do
    with_timezone("America/Los_Angeles") do
      Time.local(2007, 9, 9, 0, 0, 0).send(@method).should == true
      Time.local(2007, 1, 9, 0, 0, 0).send(@method).should == false
    end
  end
end
