describe "Localization macros" do
  it "gets a localized version of a string from the main bundle and main table" do
    NSLocalizedString("a string key", nil).should == 'from the default Localizable.strings file'
  end

  it "gets a localized version of a string from the main bundle and a specific table" do
    NSLocalizedStringFromTable("a string key", nil, nil).should == 'from the default Localizable.strings file'
    NSLocalizedStringFromTable("a string key", "OtherTable", nil).should == 'from the OtherTable.strings file'
  end

  before do
    @mainBundle = NSBundle.mainBundle
    @otherBundle = NSBundle.bundleWithURL(@mainBundle.URLForResource("AnotherBundle", withExtension:"bundle"))
  end

  it "gets a localized version of a string from a specific table and bundle" do
    NSLocalizedStringFromTableInBundle("a string key", nil, @mainBundle, nil).should == 'from the default Localizable.strings file'
    NSLocalizedStringFromTableInBundle("a string key", "OtherTable", @mainBundle, nil).should == 'from the OtherTable.strings file'
    NSLocalizedStringFromTableInBundle("a string key", "AnotherTable", @otherBundle, nil).should == 'from the AnotherBundle.bundle/AnotherTable.strings file'
  end

  it "gets a localized version of a string or defaults to a value provided from a specific table and bundle" do
    NSLocalizedStringWithDefaultValue("a string key", nil, @mainBundle, "default value", nil).should == 'from the default Localizable.strings file'
    NSLocalizedStringWithDefaultValue("another string key", nil, @mainBundle, "default value", nil).should == 'default value'

    NSLocalizedStringWithDefaultValue("a string key", "OtherTable", @mainBundle, "default value", nil).should == 'from the OtherTable.strings file'
    NSLocalizedStringWithDefaultValue("another string key", "OtherTable", @mainBundle, "default value", nil).should == 'default value'

    NSLocalizedStringWithDefaultValue("a string key", "AnotherTable", @otherBundle, "default value", nil).should == 'from the AnotherBundle.bundle/AnotherTable.strings file'
    NSLocalizedStringWithDefaultValue("another string key", "AnotherTable", @otherBundle, "default value", nil).should == 'default value'
  end
end
