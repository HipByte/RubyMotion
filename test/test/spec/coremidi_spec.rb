# We test these mainly because gen_bridge_metadata doesn't produce the metadata
# for the various types on all archs, notably 64-bit.
describe "CoreMidi" do
  it "can list devices" do
    n = MIDIGetNumberOfDevices()
    n.should > 0
    n.times do |i|
      device = MIDIGetDevice(i)
      device.class.should == ((bits == 32) ? MIDIDeviceRef : Fixnum)
    end
  end

  it "can create types" do
    clientPointer = Pointer.new(MIDIClientRef.type)
    MIDIClientCreate('Client', nil, nil, clientPointer)
    clientRef = clientPointer[0]
    clientRef.class.should == ((bits == 32) ? MIDIClientRef : Fixnum)

    outputPointer = Pointer.new(MIDIPortRef.type)
    MIDIOutputPortCreate(clientRef, 'Output', outputPointer)
    outputRef = outputPointer[0]
    outputRef.class.should == ((bits == 32) ? MIDIPortRef : Fixnum)

    MIDIPortDispose(outputRef)
    MIDIClientDispose(clientRef)
  end
end
