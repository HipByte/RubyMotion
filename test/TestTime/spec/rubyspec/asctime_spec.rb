# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/asctime', __FILE__)

# describe "Time#asctime" do
#   it_behaves_like(:time_asctime, :asctime)
# end
describe "Time#asctime" do
  before do
    @method = :asctime
  end

  it "returns a canonical string representation of time" do
    t = Time.now
    t.send(@method).should == t.strftime("%a %b %e %H:%M:%S %Y")
  end
end
