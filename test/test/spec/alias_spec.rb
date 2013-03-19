class AliasSpec
  attr_accessor :value
  def initialize
     @value = 42
  end

  class << self
    alias :foo :new
    alias_method :bar, :new
  end
end


describe "alias/alias_method" do
  it "should work on new method" do
    # RM-56 Can't use alias or alias_method on new method
    AliasSpec.foo.value.should == AliasSpec.bar.value
  end
end
