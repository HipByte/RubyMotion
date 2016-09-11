class MyAudioUnit < AUAudioUnit

  MyParam1 = 0

  # Warning: these need to be methods and not an attr_accessor in order to be
  # called from Objective-C
  def parameterTree
    @parameterTree
  end

  def parameterTree=(parameterTree)
    @parameterTree = parameterTree
  end

  def initWithComponentDescription(componentDescription, options:options, error:outError)
    super

    NSLog("initWithComponentDescription")

    # Create parameter objects.
    param1 = AUParameterTree.createParameterWithIdentifier("param1",
      name: "Parameter 1",
      address: MyParam1,
      min: 0,
      max: 100,
      unit: KAudioUnitParameterUnit_Percent,
      unitName: nil,
      flags: 0,
      valueStrings: nil,
      dependentParameters: nil)

    # Initialize the parameter values.
    param1.value = 0.5;

    # Create the parameter tree.
    self.parameterTree = AUParameterTree.createTreeWithChildren([param1])

    # Create the input and output busses (AUAudioUnitBus).
    # Create the input and output bus arrays (AUAudioUnitBusArray).

    # A function to provide string representations of parameter values.
    self.parameterTree.implementorStringFromValueCallback = proc do |param, valuePtr|
      value = valuePtr == nil ? param.value : valuePtr.value

      case param.address
      when MyParam1 then value.to_s
      else
        "?"
      end
    end

    self.maximumFramesToRender = 512
    self
  end

  # AUAudioUnit Overrides

  # If an audio unit has input, an audio unit's audio input connection points.
  # Subclassers must override this property getter and should return the same object every time.
  # See sample code.
  #
  def inputBusses
    NSLog("inputBusses")
    # warning implementation must return non-nil AUAudioUnitBusArray
    nil
  end

  # An audio unit's audio output connection points.
  # Subclassers must override this property getter and should return the same object every time.
  # See sample code.
  def outputBusses
    NSLog("outputBusses")
    # warning implementation must return non-nil AUAudioUnitBusArray
    nil
  end

  # Allocate resources required to render.
  # Subclassers should call the superclass implementation.
  def allocateRenderResourcesAndReturnError(outError)
    NSLog("allocateRenderResourcesAndReturnError")
    return false if !super

    # Validate that the bus formats are compatible.
    # Allocate your resources.

    true
  end

  # Deallocate resources allocated in allocateRenderResourcesAndReturnError:
  # Subclassers should call the superclass implementation.
  def deallocateRenderResources
    NSLog("deallocateRenderResources")
    # Deallocate your resources.
    super
  end

  # AUAudioUnit (AUAudioUnitImplementation)

  # Block which subclassers must provide to implement rendering.
  def internalRenderBlock
    NSLog("internalRenderBlock")
    # Capture in locals to avoid Obj-C member lookups. If "self" is captured in render, we're doing it wrong. See sample code.

    proc do |actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock|
      # Do event handling and signal processing here.
      NSLog("internalRenderBlock block")
      noErr
    end
  end

end
