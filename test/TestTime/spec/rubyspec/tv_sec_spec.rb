# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/to_i', __FILE__)

# describe "Time#tv_sec" do
#   it_behaves_like(:time_to_i, :tv_sec)
# end

describe "Time#tv_sec" do
  before do
    @method = :tv_sec
  end

  it "returns the value of time as an integer number of seconds since epoch" do
    Time.at(0).send(@method).should == 0
  end
end
