class TestConformsToProtocolObject1
  def requiredMethod1; 42; end
  def requiredMethod2; 42; end
end

class TestConformsToProtocolObject2
  def requiredMethod1; 42; end
  def requiredMethod2; 42; end
  def optionalMethod3; 42; end
end

class TestObjCSubclassConformsToProtocolObject < CALayer
  def requiredMethod1; 42; end
  def requiredMethod2; 42; end
end

describe "conformsToProtocol:" do
  it "works on Ruby objects implementing required methods" do
    TestMethod.testConformsToProtocol(TestConformsToProtocolObject1.new).should == true
  end

  it "works on Ruby objects implementing all methods" do
    TestMethod.testConformsToProtocol(TestConformsToProtocolObject2.new).should == true
  end

  it "works on Ruby subclasses of pure Objective-C classes" do
    TestObjCSubclassConformsToProtocolObject.conformsToProtocol(NSProtocolFromString('TestConformsToProtocol')).should == true
    TestObjCSubclassConformsToProtocolObject.new.conformsToProtocol(NSProtocolFromString('TestConformsToProtocol')).should == true
  end
end

describe "A protocol method" do
  it "warns when overriding a method defined with the `attr_reader' macro" do
    class TestConformsToProtocolObject4
      attr_reader :requiredMethod1
    end

    warning = capture_warning do
      class TestConformsToProtocolObject4
        def requiredMethod1; 42; end
      end
    end
    warning.should.match /protocol method `TestConformsToProtocolObject4#requiredMethod1'/
  end

  xit "warns when overriding a method defined with the `attr_writer' macro" do
    class TestConformsToProtocolObject5
      attr_reader :requiredMethod1
    end

    warning = capture_warning do
      class TestConformsToProtocolObject5
        #def requiredMethod1=(x); x; end
        def setRequiredMethod1(x); x; end
      end
    end
    warning.should.match /protocol method `TestConformsToProtocolObject5#requiredMethod1='/
  end
end
