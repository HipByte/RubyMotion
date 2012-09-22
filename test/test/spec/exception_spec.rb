describe "NSExceptions" do
  it "can be catched" do
    exc_name = 'TestException'
    exc_reason = 'some reason'
    exc_userInfo = { 'One' => 1, 'Two' => 2, 'Three' => 3}
    begin
      NSException.exceptionWithName(exc_name, reason:exc_reason, userInfo:exc_userInfo).raise
    rescue => e
      nse = e.nsexception
      nse.should != nil
      nse.name.should == exc_name
      nse.reason.should == exc_reason
      nse.userInfo.should == exc_userInfo
    end
  end
end
