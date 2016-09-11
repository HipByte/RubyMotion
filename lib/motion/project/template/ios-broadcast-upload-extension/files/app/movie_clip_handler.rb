class MovieClipHandler < RPBroadcastMP4ClipHandler

  def processMP4ClipWithURL(mp4ClipURL, setupInfo:setupInfo, finished:finished)
    # Get the endpoint URL supplied by the UI extension in the service info dictionary
    endpointURL = NSURL.URLWithString(setupInfo["endpointURL"])

    # Set up the request
    request = NSMutableURLRequest.alloc.initWithURL(endpointURL)
    request.setHTTPMethod("POST")

    # Upload the movie file with an upload task
    session = NSURLSession.sharedSession
    uploadTask = session.uploadTaskWithRequest(request, fromFile:mp4ClipURL, completionHandler:proc do |data, response, error|
      if error
        # Handle the error locally
      end

      # Update broadcast settings
      broadcastConfiguration = RPBroadcastConfiguration.new
      broadcastConfiguration.clipDuration = 5

      # Tell ReplayKit that processing is complete for thie clip
      self.finishedProcessingMP4ClipWithUpdatedBroadcastConfiguration(broadcastConfiguration, error:nil)
    end)

    uploadTask.resume
  end
end
