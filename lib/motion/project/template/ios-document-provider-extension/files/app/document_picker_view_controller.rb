class DocumentPickerViewController < UIDocumentPickerExtensionViewController

  def openDocument
    documentURL = self.documentStorageURL.URLByAppendingPathComponent("Untitled.txt")

    # TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
    self.dismissGrantingAccessToURL(documentURL)
  end

  def prepareForPresentationInMode(mode)
    self.view.backgroundColor = UIColor.redColor

    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setTitle("Tap to open document", forState: UIControlStateNormal)
    button.setTitleColor(UIColor.whiteColor, forState: UIControlStateNormal)
    button.addTarget(self, action: :openDocument, forControlEvents: UIControlEventTouchUpInside)
    button.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.view.addSubview(button)

    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[button]-|", options:0, metrics:nil, views:{ "button" => button }))
    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[button]-|", options:0, metrics:nil, views:{ "button" => button }))
  end

end
