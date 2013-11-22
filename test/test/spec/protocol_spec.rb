class TestConformsToProtocolObject1
  def requiredMethod1; 42; end
  def requiredMethod2; 42; end
end

class TestConformsToProtocolObject2
  def requiredMethod1; 42; end
  def requiredMethod2; 42; end
  def optionalMethod3; 42; end
end

class TestObjCSubclassConformsToProtocolObject < UIViewController
  def tableView(tableView, cellForRowAtIndexPath:indexPath); end
  def tableView(tableView, numberOfRowsInSection:section); end
end

describe "conformsToProtocol:" do
  it "works on Ruby objects implementing required methods" do
    TestMethod.testConformsToProtocol(TestConformsToProtocolObject1.new).should == true
  end

  it "works on Ruby objects implementing all methods" do
    TestMethod.testConformsToProtocol(TestConformsToProtocolObject2.new).should == true
  end

  it "works on Ruby subclasses of pure Objective-C classes" do
    TestObjCSubclassConformsToProtocolObject.conformsToProtocol(NSProtocolFromString('UITableViewDataSource')).should == true
    TestObjCSubclassConformsToProtocolObject.new.conformsToProtocol(NSProtocolFromString('UITableViewDataSource')).should == true
  end
end
