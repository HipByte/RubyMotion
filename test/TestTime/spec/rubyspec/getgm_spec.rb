# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/getgm', __FILE__)

# describe "Time#getgm" do
#   it_behaves_like(:time_getgm, :getgm)
# end
describe "Time#getgm" do
  before do
    @method = :getgm
  end

  it "returns a new time which is the utc representation of time" do
    # Testing with America/Regina here because it doesn't have DST.
    with_timezone("CST", -6) do
      t = Time.local(2007, 1, 9, 6, 0, 0)
      t.send(@method).should == Time.gm(2007, 1, 9, 12, 0, 0)
    end
  end
end
