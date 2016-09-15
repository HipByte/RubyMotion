class BroadcastViewController < UIViewController
  # Enable 'IB' if you want to use storyboard.
  # extend IB

  def viewDidLoad
    super

    label = UILabel.alloc.init
    label.text = "Hello World"
    label.textColor = UIColor.whiteColor
    label.textAlignment = NSTextAlignmentCenter
    label.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.view.addSubview(label)

    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options:0, metrics:nil, views:{ "label" => label }))
    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-|", options:0, metrics:nil, views:{ "label" => label }))
  end

  # Called when the user has finished interacting with the view controller and a broadcast stream can start
  def userDidFinishSetup
    # Broadcast url that will be returned to the application
    broadcastURL = NSURL.URLWithString("http://broadcastURL_example/stream1")

    # Service specific broadcast data example which will be supplied to the process extension during broadcast
    userID = "user1"
    endpointURL = "http://broadcastURL_example/stream1/upload"
    setupInfo = { userID: userID, endpointURL: endpointURL }

    # Set broadcast settings
    broadcastConfig = RPBroadcastConfiguration.new
    broadcastConfig.clipDuration = 5 # deliver movie clips every 5 seconds

    # Tell ReplayKit that the extension is finished setting up and can begin broadcasting
    self.extensionContext.completeRequestWithBroadcastURL(broadcastURL, broadcastConfiguration:broadcastConfig, setupInfo:setupInfo)
  end

  def userDidCancelSetup
    # Tell ReplayKit that the extension was cancelled by the user
    self.extensionContext.cancelRequestWithError(NSError.errorWithDomain("YourAppDomain", code:-1, userInfo:nil))
  end

end
