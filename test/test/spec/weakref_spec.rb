describe "WeakRef" do
  it "creates proxy objects that forward messages" do
    ary = [1, 2, 3]
    ref = WeakRef.new(ary)
    ref.class.should == Array
    ref[0].should == 1
    ref[1].should == 2
    ref[2].should == 3
    ref.should == ary
  end

  it "creates proxy objects that forward respond_to?" do
    ary = [1, 2, 3]
    ref = WeakRef.new(ary)
    ary.methods.each { |x| ref.respond_to?(x).should == true }
  end

  it "creates weak references" do
    obj = Object.new
    rc = obj.retainCount
    ref = WeakRef.new(obj)
    obj.retainCount.should == rc
  end

  it "passes the internal reference when given to ObjC APIs" do
    ary = [1, 2, 3]
    ref = WeakRef.new(ary)
    ary2 = NSArray.arrayWithArray(ref)
    ary2.should == ary
  end

  it "cannot be subclassed" do
    lambda { class Foo < WeakRef; end }.should.raise(RuntimeError)
  end
end
