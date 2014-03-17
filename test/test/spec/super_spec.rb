class Base
  def bar(args)
    $spec_result << args.first
    if args = args[1..-1]
      obj = Foo.new
      obj.bar(args)
    end
  end
end

class Foo < Base
  def bar(args)
    $spec_result << "a"
    super
  end
end

class B < (defined?(UIView) ? UIView : NSView)
  def frame=(value)
    NSLog "Calling B with #{value}"
    super
  end
end

class C < B
  def frame=(value)
    NSLog "Calling C with #{value}"
    super(value)
  end
end

$spec_result = []

describe "'super'" do
  it "should work when calls inherited class method in super method" do
    obj = Foo.new
    obj.bar(%w{1 2 3})
    $spec_result.should == ["a", "1", "a", "2", "a", "3", "a", nil]
  end

  it "should lookup shortcut method" do
    # RM-322
    c = C.alloc.init
    c.frame = [[42,0],[0,0]]
    c.frame.origin.x.should == 42
  end

end
