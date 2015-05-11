class ShareViewController < SLComposeServiceViewController

  def isContentValid
    # Do validation of contentText and/or NSExtensionContext attachments here
    true
  end

  def didSelectPost
    # This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.

    # Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    self.extensionContext.completeRequestReturningItems(nil, completionHandler:nil)
  end

  def configurationItems
    # To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    []
  end

end
