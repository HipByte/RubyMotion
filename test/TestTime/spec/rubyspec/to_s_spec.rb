# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/inspect', __FILE__)

# describe "Time#to_s" do
#   it_behaves_like :inspect, :to_s
# end
describe "Time#to_s" do
  before do
    @method = :to_s
  end

  # INFO: Not support Ruby 1.8 behavior
  # ruby_version_is ""..."1.9" do
  #   it "formats the time following the pattern 'EEE MMM dd HH:mm:ss Z yyyy'" do
  #     with_timezone("PST", +1) do
  #       Time.local(2000, 1, 1, 20, 15, 1).send(@method).should == "Sat Jan 01 20:15:01 +0100 2000"
  #     end
  #   end

  #   it "formats the UTC time following the pattern 'EEE MMM dd HH:mm:ss UTC yyyy'" do
  #     Time.utc(2000, 1, 1, 20, 15, 1).send(@method).should == "Sat Jan 01 20:15:01 UTC 2000"
  #   end
  # end

  ruby_version_is "1.9" do
    it "formats the local time following the pattern 'yyyy-MM-dd HH:mm:ss Z'" do
      with_timezone("PST", +1) do
        Time.local(2000, 1, 1, 20, 15, 1).send(@method).should == "2000-01-01 20:15:01 +0100"
      end
    end

    it "formats the UTC time following the pattern 'yyyy-MM-dd HH:mm:ss UTC'" do
      Time.utc(2000, 1, 1, 20, 15, 1).send(@method).should == "2000-01-01 20:15:01 UTC"
    end

    it "formats the fixed offset time following the pattern 'yyyy-MM-dd HH:mm:ss +/-HHMM'" do
      Time.new(2000, 1, 1, 20, 15, 01, 3600).send(@method).should == "2000-01-01 20:15:01 +0100"
    end
  end
end
