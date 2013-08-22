# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/to_i', __FILE__)

# describe "Time#to_i" do
#   it_behaves_like(:time_to_i, :to_i)
# end
describe "Time#to_i" do
  before do
    @method = :to_i
  end

  it "returns the value of time as an integer number of seconds since epoch" do
    Time.at(0).send(@method).should == 0
  end
end
