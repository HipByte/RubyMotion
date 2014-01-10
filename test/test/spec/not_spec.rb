class TestBang1
  def !
    42
  end
end

class TestBang2
  define_method(:!) do
    "foo"
  end
end

# RM-72
describe "! method" do
  it "should be called" do
    obj = Object.new
    (!obj).should == false

    obj = TestBang1.new
    (!obj).should == 42

    obj = TestBang2.new
    (!obj).should == "foo"
  end
end
