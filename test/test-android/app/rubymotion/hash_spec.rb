describe "Hashes" do
  it "are based on java.util.HashMap" do
    Hash.should == Java::Util::HashMap
    {}.class.should == Java::Util::HashMap
  end
end
