class TestArchiver
  attr_accessor :name

  def encodeWithCoder(encoder)
    encoder.encodeObject(self.name, forKey: "name")
  end
  
  def initWithCoder(decoder)
    if self.init
      self.name = decoder.decodeObjectForKey("name")
    end
    self
  end
end

describe "NSKeyedArchiver" do
  it "works" do
    m = TestArchiver.new
    m.name = "test"

    m2 = NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(m))
    m2.class.should == TestArchiver
    m2.name.should == m.name
  end
end
