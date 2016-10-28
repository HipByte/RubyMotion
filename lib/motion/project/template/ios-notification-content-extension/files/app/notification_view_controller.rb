class NotificationViewController < UIViewController
  # Enable 'IB' if you want to use storyboard.
  # extend IB

  attr_accessor :label

  def viewDidLoad
    self.view.backgroundColor = UIColor.redColor

    self.label = UILabel.alloc.init
    label.text = "Hello World"
    label.textColor = UIColor.whiteColor
    label.textAlignment = NSTextAlignmentCenter
    label.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.view.addSubview(label)

    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options:0, metrics:nil, views:{ "label" => label }))
    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-|", options:0, metrics:nil, views:{ "label" => label }))
  end

  def didReceiveNotification(notification)
    self.label.text = notification.request.content.body
  end

end
