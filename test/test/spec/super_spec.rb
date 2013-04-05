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

$spec_result = []

describe "'super'" do
  it "should work when calls inherited class method in super method" do
    obj = Foo.new
    obj.bar(%w{1 2 3})
    $spec_result.should == ["a", "1", "a", "2", "a", "3", "a", nil]
  end
end
