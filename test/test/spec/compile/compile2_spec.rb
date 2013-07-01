# geomotion/lib/geomotion/cg_affine_transform.rb
class CGAffineTransform
  def self.make(options)
    if options.key?(:a)
      args = [:a, :b].map do |key|
        options[key]
      end
    else
      options[:translate]
    end
  end
end

describe "compile2_spec" do
  it "should work" do
	CGAffineTransform.make({:a => 42, :b => 7}).should == [42, 7]
  end
end