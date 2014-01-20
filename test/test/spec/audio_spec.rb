# https://hipbyte.freshdesk.com/helpdesk/tickets/1514
describe "AudioToolbox" do
  it "cftype structure should work" do
    AUGraph.type.should == "^{OpaqueAUGraph=}"
  end
end
