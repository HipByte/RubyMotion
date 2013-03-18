describe "Boxed" do
  it ".type should work with structure which has field of structure pointer" do
    MyStructHasStructPointer.type.should == "{MyStructHasStructPointer=^{MyStruct4C}}"
  end
end
