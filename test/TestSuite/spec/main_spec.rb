describe "Application 'TestSuite'" do
  it "should finish without error/failure" do
    $testsuite_error.should == 0
    $testsuite_failure.should == 0
  end
end
