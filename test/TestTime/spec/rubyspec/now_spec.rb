# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/now', __FILE__)

# describe "Time.now" do
#   it_behaves_like(:time_now, :now)
# end
describe "Time.now" do
  before do
    @method = :now
  end

  # platform_is_not :windows do
    it "creates a time based on the current system time" do
      # unless `which date` == ""
        Time.__send__(@method).to_i.should == `date +%s`.to_i
      # end
    end
  # end

  it "creates a subclass instance if called on a subclass" do
    TimeSpecs::SubTime.now.kind_of?(TimeSpecs::SubTime).should == true
  end
end
