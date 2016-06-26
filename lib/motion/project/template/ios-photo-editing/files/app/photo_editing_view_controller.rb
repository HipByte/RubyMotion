class PhotoEditingViewController < UIViewController

  attr_accessor :input

  def viewDidLoad
    super

    self.view.backgroundColor = UIColor.whiteColor

    label = UILabel.alloc.init
    label.text = "Hello World"
    label.textColor = UIColor.blackColor
    label.textAlignment = NSTextAlignmentCenter
    label.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.view.addSubview(label)

    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options:0, metrics:nil, views:{"label" => label}))
    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-|", options:0, metrics:nil, views:{"label" => label}))
  end

  def didReceiveMemoryWarning
    super
    # Dispose of any resources that can be recreated.
  end

  # PHContentEditingController

  def canHandleAdjustmentData(adjustmentData)
    # Inspect the adjustmentData to determine whether your extension can work with past edits.
    # (Typically, you use its formatIdentifier and formatVersion properties to do this.)
    false
  end

  def startContentEditingWithInput(contentEditingInput, placeholderImage:placeholderImage)
    # Present content for editing, and keep the contentEditingInput for use when closing the edit session.
    # If you returned YES from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
    # If you returned NO, the contentEditingInput has past edits "baked in".
    self.input = contentEditingInput
  end

  def finishContentEditingWithCompletionHandler(completionHandler)
    # Update UI to reflect that editing has finished and output is being rendered.

    # Render and provide output on a background queue.

    Dispatch::Queue.concurrent {
      # Create editing output from the editing input.
      output = PHContentEditingOutput.alloc.initWithContentEditingInput(self.input)

      # Provide new adjustments and render output to given location.
      # output.adjustmentData = <#new adjustment data#>;
      # NSData *renderedJPEGData = <#output JPEG#>;
      # [renderedJPEGData writeToURL:output.renderedContentURL atomically:YES];

      # Call completion handler to commit edit to Photos.
      completionHandler.call(output)

      # Clean up temporary files, etc.
    }
  end

  def cancelContentEditing
    # Clean up temporary files, etc.
    # May be called after finishContentEditingWithCompletionHandler: while you prepare output.
  end

end
