class RunloopYield
  def initialize(&b)
    @b = b
    run
  end

  def run
    performSelectorOnMainThread(:'test_start', withObject:nil, waitUntilDone:false)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))    
  end

  def test_start
    @b.call
  end
end
