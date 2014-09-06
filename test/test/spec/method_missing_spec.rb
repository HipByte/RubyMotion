# RM-586
describe "method_missing" do
  class TestMethodMissingWithKeywordArgs
    def method_missing(method_name, *args)
      method_name.should == :"meth:test:"
      args.should == [42, "foo"]
    end
  end

  it "should receive non hash object with keyword argument" do
    obj = TestMethodMissingWithKeywordArgs.new
    obj.meth(42, test:"foo")
    obj.meth(42, test:"foo")
  end

  class TestMethodMissingWithNoKeywordArgs
    def method_missing(method_name, *args)
      method_name.should == :"meth"
      args.should == [42, {test: "foo"}]
    end
  end

  it "should receive hash object without keyword argument" do
    obj = TestMethodMissingWithNoKeywordArgs.new
    obj.meth(42, {test: "foo"})
    obj.meth(42, {test: "foo"})
  end
end
