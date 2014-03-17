describe "NSExceptions" do
  xit "can be caught (1)" do
    exc_name = 'TestException'
    exc_reason = 'some reason'
    exc_userInfo = { 'One' => 1, 'Two' => 2, 'Three' => 3}
    begin
      NSException.exceptionWithName(exc_name, reason:exc_reason, userInfo:exc_userInfo).raise
    rescue => e
      e.name.should == exc_name
      e.reason.should == exc_reason
      e.userInfo.should == exc_userInfo
    end
  end

  xit "can be caught (2)" do
    begin
      NSString.stringWithString(42)
    rescue => e
      e.class.should == NSException
      e.name.should == 'NSInvalidArgumentException'
    end
  end

  xit "should be raised with Kernel.raise" do
    begin
      raise NSException.exceptionWithName('NSInvalidArgumentException', reason:'Woops!', userInfo:nil)
    rescue => e
      e.class.should == NSException
      e.name.should == 'NSInvalidArgumentException'
    end
  end
end
