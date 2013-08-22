# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/asctime', __FILE__)

# describe "Time#ctime" do
#   it_behaves_like(:time_asctime, :ctime)
# end
describe "Time#ctime" do
  before do
    @method = :ctime
  end

  it "returns a canonical string representation of time" do
    t = Time.now
    t.send(@method).should == t.strftime("%a %b %e %H:%M:%S %Y")
  end
end
