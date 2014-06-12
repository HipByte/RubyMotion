class TestJavaMethodsOverride < Com::RubyMotion::Test::TestJavaMethods
  def booleanMethod(arg); arg; end
  def byteMethod(arg); arg; end
  def shortMethod(arg); arg; end
  def intMethod(arg); arg; end
  def longMethod(arg); arg; end
  def floatMethod(arg); arg; end
  def doubleMethod(arg); arg; end
  def objectMethod(arg); arg; end
end

2.times do |spec_n|
  describe "Java methods" + (spec_n == 0 ? "" : " overriden in Ruby") + " can be called when accepting/returning" do
    before :each do
      @obj = spec_n == 0 ? Com::RubyMotion::Test::TestJavaMethods.new : TestJavaMethodsOverride.new
    end
  
    it "'boolean'" do
      @obj.booleanMethod(true).should == true
      @obj.booleanMethod(42).should == true
      @obj.booleanMethod(false).should == false
      @obj.booleanMethod(nil).should == false
    end
  
    it "'byte'" do
      ret = @obj.byteMethod(42)
      ret.should be_an_instance_of(Java::Lang::Byte)
      ret.intValue.should == 42
    end
  
    it "'short'" do
      ret = @obj.shortMethod(42)
      ret.should be_an_instance_of(Java::Lang::Short)
      ret.intValue.should == 42
    end
  
    it "'int'" do
      @obj.intMethod(42).should == 42
    end
  
    it "'long'" do
      ret = @obj.longMethod(42)
      ret.should be_an_instance_of(Java::Lang::Long)
      ret.intValue.should == 42
    end
  
    it "'float'" do
      @obj.floatMethod(3.14).should == 3.14
    end
  
    it "'double'" do
      ret = @obj.doubleMethod(3.14)
      ret.should be_an_instance_of(Java::Lang::Double)
      ret.floatValue.should == 3.14
    end

    it "'java.lang.Object'" do
      obj = Java::Lang::Object.new
      ret = @obj.objectMethod(obj)
      obj.should == ret
      obj.should equal(ret)
    end
  end
end
