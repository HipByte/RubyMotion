describe "Hash" do
  it 'can be created using []' do
    h = Hash[a: 'a', b: 'b']
    h[:a].should == 'a'
    h[:b].should == 'b'
  end
end
