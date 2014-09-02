describe "Method" do
  class TestMethodA
    def foo
    end
  end


  class TestMethodB < TestMethodA
    def foo
    end
  end

  class TestMethodC < TestMethodA
  end

  # RM-541
  it "#owner should return correct owner if override the method in inherited class" do
    TestMethodB.new.method(:foo).owner.should == TestMethodB
    TestMethodC.new.method(:foo).owner.should == TestMethodA
  end
end