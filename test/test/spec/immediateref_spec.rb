describe "ImmediateRef" do
  class << self
    # Tagged pointers are only available on 64-bit platforms.
    alias_method :on_64bit_it, RUBY_ARCH =~ /64/ ? :it : :xit
  end

  on_64bit_it "forwards messages to the wrapped tagged pointer object" do
    ref = NSIndexPath.indexPathWithIndex(42)
    ref.indexAtPosition(0).should == 42
    ref.should == NSIndexPath.indexPathWithIndex(42)
  end

  on_64bit_it "returns the tagged pointer object's class" do
    ref = NSIndexPath.indexPathWithIndex(42)
    ref.class.should == NSIndexPath
  end

  on_64bit_it "returns the tagged pointer object's methods" do
    ref = NSIndexPath.indexPathWithIndex(42)
    ref.methods(false).should == NSIndexPath.public_instance_methods(false)
  end

  on_64bit_it "returns the tagged pointer object's description" do
    ref = NSIndexPath.indexPathWithIndex(42)
    ref.inspect.should.match /#<ImmediateRef:0x\h+ <NSIndexPath: 0x\h+> \{length = 1, path = 42\}>/
  end

  on_64bit_it "stays an ImmediateRef when calling a Ruby method on it" do
    class NSIndexPath
      def ruby_instance_method
        self
      end
    end
    ref = NSIndexPath.indexPathWithIndex(42)
    ref.ruby_instance_method.should.eql ref
  end

  on_64bit_it "is able to dispatch methods to itself" do
    class NSIndexPath
      def ruby_instance_method
        self.indexAtPosition(0)
      end
    end
    ref = NSIndexPath.indexPathWithIndex(42)
    ref.ruby_instance_method.should == 42
  end
end
