# To handle samples with a subclass of RPBroadcastSampleHandler set the following in the extension's Info.plist file:
# - RPBroadcastProcessMode should be set to RPBroadcastProcessModeSampleBuffer
# - NSExtensionPrincipalClass should be set to this class

class SampleHandler < RPBroadcastSampleHandler

  def broadcastStartedWithSetupInfo(setupInfo)
    # User has requested to start the broadcast. Setup info from the UI extension will be supplied.
  end

  def broadcastPaused
    # User has requested to pause the broadcast. Samples will stop being delivered.
  end

  def broadcastResumed
    # User has requested to resume the broadcast. Samples delivery will resume.
  end

  def broadcastFinished
    # User has requested to finish the broadcast.
  end

  def processSampleBuffer(sampleBuffer, withType:sampleBufferType)
    case sampleBufferType
    when RPSampleBufferTypeVideo
      # Handle audio sample buffer
    when RPSampleBufferTypeAudioApp
      # Handle audio sample buffer for app audio
    when RPSampleBufferTypeAudioMic
      # Handle audio sample buffer for mic audio
    end
  end

end
