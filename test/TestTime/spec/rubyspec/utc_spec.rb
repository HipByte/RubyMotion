# require File.expand_path('../../../spec_helper', __FILE__)
# require File.expand_path('../fixtures/methods', __FILE__)
# require File.expand_path('../shared/gm', __FILE__)
# require File.expand_path('../shared/gmtime', __FILE__)
# require File.expand_path('../shared/time_params', __FILE__)

describe "Time#utc?" do
  it "returns true if time represents a time in UTC (GMT)" do
    Time.now.utc?.should == false
  end
end

# describe "Time.utc" do
#   it_behaves_like(:time_gm, :utc)
#   it_behaves_like(:time_params, :utc)
#   it_behaves_like(:time_params_10_arg, :utc)
#   it_behaves_like(:time_params_microseconds, :utc)
# end


describe "Time.utc" do
  before do
    @method = :utc
  end

  # INFO: Not support Ruby 1.8 behavior
  # ruby_version_is ""..."1.9" do
  #   it "creates a time based on given values, interpreted as UTC (GMT)" do
  #     Time.send(@method, 2000,"jan",1,20,15,1).inspect.should == "Sat Jan 01 20:15:01 UTC 2000"
  #   end

  #   it "creates a time based on given C-style gmtime arguments, interpreted as UTC (GMT)" do
  #     time = Time.send(@method, 1, 15, 20, 1, 1, 2000, :ignored, :ignored, :ignored, :ignored)
  #     time.inspect.should == "Sat Jan 01 20:15:01 UTC 2000"
  #   end
  # end

  ruby_version_is "1.9" do
    it "creates a time based on given values, interpreted as UTC (GMT)" do
      Time.send(@method, 2000,"jan",1,20,15,1).inspect.should == "2000-01-01 20:15:01 UTC"
    end

    it "creates a time based on given C-style gmtime arguments, interpreted as UTC (GMT)" do
      time = Time.send(@method, 1, 15, 20, 1, 1, 2000, :ignored, :ignored, :ignored, :ignored)
      time.inspect.should == "2000-01-01 20:15:01 UTC"
    end
  end

  it "interprets pre-Gregorian reform dates using Gregorian proleptic calendar" do
    Time.send(@method, 1582, 10, 4, 12).to_i.should == -12220200000 # 2299150j
  end

  it "interprets Julian-Gregorian gap dates using Gregorian proleptic calendar" do
    Time.send(@method, 1582, 10, 14, 12).to_i.should == -12219336000 # 2299160j
  end

  it "interprets post-Gregorian reform dates using Gregorian calendar" do
    Time.send(@method, 1582, 10, 15, 12).to_i.should == -12219249600 # 2299161j
  end

  it "accepts 1 argument (year)" do
    Time.send(@method, 2000).should ==
      Time.send(@method, 2000, 1, 1, 0, 0, 0)
  end

  it "accepts 2 arguments (year, month)" do
    Time.send(@method, 2000, 2).should ==
      Time.send(@method, 2000, 2, 1, 0, 0, 0)
  end

  it "accepts 3 arguments (year, month, day)" do
    Time.send(@method, 2000, 2, 3).should ==
      Time.send(@method, 2000, 2, 3, 0, 0, 0)
  end

  it "accepts 4 arguments (year, month, day, hour)" do
    Time.send(@method, 2000, 2, 3, 4).should ==
      Time.send(@method, 2000, 2, 3, 4, 0, 0)
  end

  it "accepts 5 arguments (year, month, day, hour, minute)" do
    Time.send(@method, 2000, 2, 3, 4, 5).should ==
      Time.send(@method, 2000, 2, 3, 4, 5, 0)
  end

  it "raises a TypeError if the year is nil" do
    lambda { Time.send(@method, nil) }.should.raise?(TypeError)
  end

  it "accepts nil month, day, hour, minute, and second" do
    Time.send(@method, 2000, nil, nil, nil, nil, nil).should ==
      Time.send(@method, 2000)
  end

  it "handles a String year" do
    Time.send(@method, "2000").should ==
      Time.send(@method, 2000)
  end

  it "coerces the year with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, m).should == Time.send(@method, 1)
  end

  it "handles a String month given as a numeral" do
    Time.send(@method, 2000, "12").should ==
      Time.send(@method, 2000, 12)
  end

  it "handles a String month given as a short month name" do
    Time.send(@method, 2000, "dec").should ==
      Time.send(@method, 2000, 12)
  end

  it "coerces the month with #to_str" do
    (obj = mock('12')).should_receive(:to_str).and_return("12")
    Time.send(@method, 2008, obj).should ==
      Time.send(@method, 2008, 12)
  end

  it "coerces the month with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, m).should == Time.send(@method, 2008, 1)
  end

  it "handles a String day" do
    Time.send(@method, 2000, 12, "15").should ==
      Time.send(@method, 2000, 12, 15)
  end

  it "coerces the day with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, m).should == Time.send(@method, 2008, 1, 1)
  end

  it "handles a String hour" do
    Time.send(@method, 2000, 12, 1, "5").should ==
      Time.send(@method, 2000, 12, 1, 5)
  end

  it "coerces the hour with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, 1, m).should == Time.send(@method, 2008, 1, 1, 1)
  end

  it "handles a String minute" do
    Time.send(@method, 2000, 12, 1, 1, "8").should ==
      Time.send(@method, 2000, 12, 1, 1, 8)
  end

  it "coerces the minute with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, 1, 0, m).should == Time.send(@method, 2008, 1, 1, 0, 1)
  end

  # INFO: Not support Ruby 2.0 behavior
  # ruby_bug "6193", "2.0" do
  #   it "handles a String second" do
  #     Time.send(@method, 2000, 12, 1, 1, 1, "8").should ==
  #       Time.send(@method, 2000, 12, 1, 1, 1, 8)
  #   end
  # end

  it "coerces the second with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, 1, 0, 0, m).should == Time.send(@method, 2008, 1, 1, 0, 0, 1)
  end

  ruby_bug "6193", "2.0" do
    it "interprets all numerals as base 10" do
      Time.send(@method, "2000", "08", "08", "08", "08", "08").should ==
        Time.send(@method, 2000, 8, 8, 8, 8, 8)
      Time.send(@method, "2000", "09", "09", "09", "09", "09").should ==
        Time.send(@method, 2000, 9, 9, 9, 9, 9)
    end
  end

  ruby_version_is "".."1.9" do
    it "ignores fractional seconds as a Float" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1.75)
      t.sec.should == 1
      # FIXME
      # t.usec.should == 0
    end
  end

  ruby_version_is "1.9" do
    it "handles fractional seconds as a Float" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1.75)
      t.sec.should == 1
      t.usec.should == 750000
    end

    it "handles fractional seconds as a Rational" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, Rational(99, 10))
      t.sec.should == 9
      t.usec.should == 900000
    end
  end

  # INFO: Not support Ruby 1.9.0 behavior
  # ruby_version_is ""..."1.9.1" do
  #   it "accepts various year ranges" do
  #     Time.send(@method, 1901, 12, 31, 23, 59, 59, 0).wday.should == 2
  #     Time.send(@method, 2037, 12, 31, 23, 59, 59, 0).wday.should == 4

  #     not_compliant_on :rubinius do
  #       platform_is :wordsize => 32 do
  #         lambda {
  #           Time.send(@method, 1900, 12, 31, 23, 59, 59, 0)
  #         }.should.raise?(ArgumentError) # mon

  #         lambda {
  #           Time.send(@method, 2038, 12, 31, 23, 59, 59, 0)
  #         }.should.raise?(ArgumentError) # mon
  #       end

  #       platform_is :wordsize => 64 do
  #         Time.send(@method, 1900, 12, 31, 23, 59, 59, 0).wday.should == 1
  #         Time.send(@method, 2038, 12, 31, 23, 59, 59, 0).wday.should == 5
  #       end
  #     end

  #     deviates_on :rubinius do
  #       Time.send(@method, 1900, 12, 31, 23, 59, 59, 0).wday.should == 1
  #       Time.send(@method, 2038, 12, 31, 23, 59, 59, 0).wday.should == 5
  #     end
  #   end

  #   not_compliant_on :rubinius do
  #     platform_is :wordsize => 32 do
  #       it "raises an ArgumentError for out of range year" do
  #         lambda {
  #           Time.send(@method, 1111, 12, 31, 23, 59, 59)
  #         }.should.raise?(ArgumentError)
  #       end
  #     end
  #   end
  # end

  ruby_version_is "1.9" do
    it "accepts various year ranges" do
      Time.send(@method, 1801, 12, 31, 23, 59, 59).wday.should == 4
      Time.send(@method, 3000, 12, 31, 23, 59, 59).wday.should == 3
    end
  end

  it "raises an ArgumentError for out of range month" do
    lambda {
      Time.send(@method, 2008, 13, 31, 23, 59, 59)
    }.should.raise?(ArgumentError)
  end

  it "raises an ArgumentError for out of range day" do
    lambda {
      Time.send(@method, 2008, 12, 32, 23, 59, 59)
    }.should.raise?(ArgumentError)
  end

  it "raises an ArgumentError for out of range hour" do
    lambda {
      Time.send(@method, 2008, 12, 31, 25, 59, 59)
    }.should.raise?(ArgumentError)
  end

  it "raises an ArgumentError for out of range minute" do
    lambda {
      Time.send(@method, 2008, 12, 31, 23, 61, 59)
    }.should.raise?(ArgumentError)
  end

  it "raises an ArgumentError for out of range second" do
    lambda {
      Time.send(@method, 2008, 12, 31, 23, 59, 61)
    }.should.raise?(ArgumentError)
  end

  it "raises ArgumentError when given 9 arguments" do
    lambda { Time.send(@method, *[0]*9) }.should.raise?(ArgumentError)
  end

  it "raises ArgumentError when given 11 arguments" do
    lambda { Time.send(@method, *[0]*11) }.should.raise?(ArgumentError)
  end

  it "returns subclass instances" do
    c = Class.new(Time)
    c.send(@method, 2008, "12").kind_of?(c).should == true
  end

  it "handles string arguments" do
    Time.send(@method, "1", "15", "20", "1", "1", "2000", :ignored, :ignored,
              :ignored, :ignored).should ==
      Time.send(@method, 1, 15, 20, 1, 1, 2000, :ignored, :ignored, :ignored, :ignored)
  end

  it "handles float arguments" do
    Time.send(@method, 1.0, 15.0, 20.0, 1.0, 1.0, 2000.0, :ignored, :ignored,
              :ignored, :ignored).should ==
      Time.send(@method, 1, 15, 20, 1, 1, 2000, :ignored, :ignored, :ignored, :ignored)
  end

  # INFO: Not support Ruby 1.9.0 behavior
  # ruby_version_is ""..."1.9.1" do
  #   it "raises an ArgumentError for out of range values" do
  #     lambda {
  #       Time.send(@method, 61, 59, 23, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
  #     }.should.raise?(ArgumentError) # sec

  #     lambda {
  #       Time.send(@method, 59, 61, 23, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
  #     }.should.raise?(ArgumentError) # min

  #     lambda {
  #       Time.send(@method, 59, 59, 25, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
  #     }.should.raise?(ArgumentError) # hour

  #     lambda {
  #       Time.send(@method, 59, 59, 23, 32, 12, 2008, :ignored, :ignored, :ignored, :ignored)
  #     }.should.raise?(ArgumentError) # day

  #     lambda {
  #       Time.send(@method, 59, 59, 23, 31, 13, 2008, :ignored, :ignored, :ignored, :ignored)
  #     }.should.raise?(ArgumentError) # month

  #     # Year range only fails on 32 bit archs
  #     not_compliant_on :rubinius do
  #       platform_is :wordsize => 32 do
  #         lambda {
  #           Time.send(@method, 59, 59, 23, 31, 12, 1111, :ignored, :ignored, :ignored, :ignored)
  #         }.should.raise?(ArgumentError) # year
  #       end
  #     end
  #   end
  # end

  ruby_version_is "1.9" do
    it "raises an ArgumentError for out of range values" do
      lambda {
        Time.send(@method, 61, 59, 23, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
      }.should.raise?(ArgumentError) # sec

      lambda {
        Time.send(@method, 59, 61, 23, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
      }.should.raise?(ArgumentError) # min

      lambda {
        Time.send(@method, 59, 59, 25, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
      }.should.raise?(ArgumentError) # hour

      lambda {
        Time.send(@method, 59, 59, 23, 32, 12, 2008, :ignored, :ignored, :ignored, :ignored)
      }.should.raise?(ArgumentError) # day

      lambda {
        Time.send(@method, 59, 59, 23, 31, 13, 2008, :ignored, :ignored, :ignored, :ignored)
      }.should.raise?(ArgumentError) # month
    end
  end

  it "handles microseconds" do
    t = Time.send(@method, 2000, 1, 1, 20, 15, 1, 123)
    t.usec.should == 123
  end

  ruby_version_is "".."1.9" do
    it "ignores fractional microseconds as a Float" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1, 1.75)
      t.usec.should == 1
    end
  end

  ruby_version_is "1.9" do
    it "handles fractional microseconds as a Float" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1, 1.75)
      t.usec.should == 1
      t.nsec.should == 1750
    end

    it "handles fractional microseconds as a Rational" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1, Rational(99, 10))
      t.usec.should == 9
      t.nsec.should == 9900
    end

    it "ignores fractional seconds if a passed whole number of microseconds" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1.75, 2)
      t.sec.should == 1
      t.usec.should == 2
      t.nsec.should == 2000
    end

    it "ignores fractional seconds if a passed fractional number of microseconds" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1.75, Rational(99, 10))
      t.sec.should == 1
      t.usec.should == 9
      t.nsec.should == 9900
    end
  end
end

# describe "Time#utc" do
#   it_behaves_like(:time_gmtime, :utc)
# end
describe "Time#utc" do
  before do
    @method = :utc
  end

  it "returns the utc representation of time" do
    # Testing with America/Regina here because it doesn't have DST.
    with_timezone("CST", -6) do
      t = Time.local(2007, 1, 9, 6, 0, 0)
      t.send(@method)
      t.should == Time.gm(2007, 1, 9, 12, 0, 0)
    end
  end
end
