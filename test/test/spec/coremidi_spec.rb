=begin
describe "CoreMidi" do
  it "can list devices" do
    n = MIDIGetNumberOfDevices()
    n.should > 0
    n.times do |i|
      device = MIDIGetDevice(i)
      device.class.should == MIDIDeviceRef
    end
  end
end
=end
