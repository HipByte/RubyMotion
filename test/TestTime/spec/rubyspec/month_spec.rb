# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/month', __FILE__)

# describe "Time#month" do
#   it_behaves_like(:time_month, :month)
# end
describe "Time#month" do
  before do
    @method = :month
  end

  it "returns the month of the year for a local Time" do
    with_timezone("CET", 1) do
      Time.local(1970, 1).send(@method).should == 1
    end
  end

  it "returns the month of the year for a UTC Time" do
    Time.utc(1970, 1).send(@method).should == 1
  end

  ruby_version_is "1.9" do
    it "returns the four digit year for a Time with a fixed offset" do
      Time.new(2012, 1, 1, 0, 0, 0, -3600).send(@method).should == 1
    end
  end
end
