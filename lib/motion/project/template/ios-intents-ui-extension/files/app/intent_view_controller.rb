# As an example, this extension has been configured to handle interactions for INSendMessageIntent.
# You will want to replace this or add other intents as appropriate.
# The intents whose interactions you wish to handle must be declared in the extension's Rakefile.

# You can test this example integration by saying things to Siri like:
# "Send a message using <myApp>"

class IntentViewController < UIViewController
  # Enable 'IB' if you want to use storyboard.
  # extend IB

  def viewDidLoad
    self.view.backgroundColor = UIColor.greenColor
  end

  # Prepare your view controller for the interaction to handle.
  def configureWithInteraction(interaction, context:context, completion:completion)
    # Do configuration here, including preparing views and calculating a desired size for presentation.

    if completion
      completion.call(self.desiredSize)
    end
  end

  def desiredSize
    self.extensionContext.hostedViewMaximumAllowedSize
  end

end
