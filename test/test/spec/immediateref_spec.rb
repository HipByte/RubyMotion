describe "ImmediateRef" do
  class << self
    # Tagged pointers are only available on 64-bit platforms.
    alias_method :on_64bit_it, RUBY_ARCH =~ /64/ ? :it : :xit
  end

  on_64bit_it "forwards messages to the wrapped tagged pointer object" do
    ref = TaggedNSObjectSubclass.taggedObject(42)
    ref.class.should == TaggedNSObjectSubclass
    ref.taggedValue.should == 42
    ref.should == TaggedNSObjectSubclass.taggedObject(42)
  end

  on_64bit_it "returns the tagged pointer object's methods" do
    ref = TaggedNSObjectSubclass.taggedObject(42)
    ref.public_methods(false).should == [:taggedValue, :'isEqualTo:']
  end

  on_64bit_it "returns the tagged pointer object's description" do
    ref = TaggedNSObjectSubclass.taggedObject(42)
    ref.inspect.should.start_with '#<TaggedNSObjectSubclass'
  end

  on_64bit_it "is able to dispatch methods to itself" do
    class TaggedNSObjectSubclass
      def ruby_instance_method
        self.taggedValue
      end
    end
    ref = TaggedNSObjectSubclass.taggedObject(42)
    ref.ruby_instance_method.should == 42
  end
end
