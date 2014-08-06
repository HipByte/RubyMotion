describe "Module#remove_method" do
  class TestRemoveA
    def qqq
      456
    end
  end

  class TestRemoveB < TestRemoveA
    def qqq
      123
    end
  end

  # RM-540
  it "superclass method should be called if call removed method" do
    TestRemoveB.new.qqq.should == 123
    TestRemoveB.send(:remove_method, :qqq)
    TestRemoveB.new.qqq.should == 456
  end
end
