# https://hipbyte.freshdesk.com/helpdesk/tickets/1514
describe "AudioToolbox" do
  it "cftype structure should work" do
    AUGraph.type.should == "^{OpaqueAUGraph=}"
  end
end

describe "AudioUnit" do
  # RM-470
  # This spec might require to update AudioToolbox/AudioUnit bridgesupport file if spec was failed.
  it "structure should work" do
    AudioComponent.type.should == "^{OpaqueAudioComponent=}"
  end
end
