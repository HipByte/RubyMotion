describe "NSExceptions" do
  it "can be catched" do
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
end
