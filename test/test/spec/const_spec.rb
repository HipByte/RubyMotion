describe "iOS constants" do
  it "have their values retrieved at demand" do
    ABAddressBookCreate()
    KABPersonFirstNameProperty.should != KABPersonLastNameProperty
  end
end
