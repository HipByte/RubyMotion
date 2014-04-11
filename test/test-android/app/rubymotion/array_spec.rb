describe "Arrays" do
  it "are based on java.util.ArrayList" do
    Array.should == Java::Util::ArrayList
    [].class.should == Java::Util::ArrayList
  end
end
