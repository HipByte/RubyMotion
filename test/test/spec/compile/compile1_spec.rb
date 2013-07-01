# BubbleWrap/motion/util/constants.rb 
module Constants
  module_function
  def get(base, values)
    case values
    when Array
      values.each { |i|
        get(base, i)
      }
    else
      Kernel.const_get("#{base}::#{values}")
    end
  end
end

describe "compile1_spec" do
  it "should work" do
    values = ["EEXIST", "EINTR"]
    Constants.get("Errno", values).should == values
  end
end