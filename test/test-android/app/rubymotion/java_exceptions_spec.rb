describe "Java exceptions" do
  it "can be catched by a rescue block" do
    lambda { Java::Util::ArrayList.new.remove(42) }.should raise_error(Exception)
  end
end
