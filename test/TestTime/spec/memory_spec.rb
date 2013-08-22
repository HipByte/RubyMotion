describe "NSDate" do
  class NSDate
    def dealloc
      $dealloc_test = true
      super
    end
  end
  it "garbaged object should call #dealloc" do
    $dealloc_test = false
    autorelease_pool do
      NSDate.new
    end
    $dealloc_test.should == true

    $dealloc_test = false
    autorelease_pool do
      NSDate.alloc.init
    end
    $dealloc_test.should == true

    $dealloc_test = false
    autorelease_pool do
      NSDate.date
    end
    $dealloc_test.should == true

    $dealloc_test = false
    @t = NSDate.date
    autorelease_pool do
      @t.copy
    end
    $dealloc_test.should == true
    @t = nil
  end
end

describe "Time" do
  class Time
    def dealloc
      $dealloc_test = true
      super
    end
  end
  it "garbaged object should call #dealloc" do
    $dealloc_test = false
    autorelease_pool do
      Time.new
    end
    $dealloc_test.should == true

    $dealloc_test = false
    autorelease_pool do
      Time.now
    end
    $dealloc_test.should == true

    $dealloc_test = false
    autorelease_pool do
      Time.alloc.init
    end
    $dealloc_test.should == true

    $dealloc_test = false
    @t = Time.now
    autorelease_pool do
      @t.dup
    end
    $dealloc_test.should == true
    @t = nil
  end
end
