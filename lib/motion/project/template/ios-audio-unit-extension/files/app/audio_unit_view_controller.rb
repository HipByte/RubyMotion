class AudioUnitViewController < AUViewController
  # Enable 'IB' if you want to use storyboard.
  # extend IB

  attr_accessor :audioUnit

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

    return if !audioUnit
  end

  def createAudioUnitWithComponentDescription(desc, error:error)
    MyAudioUnit.alloc.initWithComponentDescription(desc, error:error)
  end

end
