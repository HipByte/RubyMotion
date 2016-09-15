class NotificationViewController
  # Enable 'IB' if you want to use storyboard.
  # extend IB

  def viewDidLoad
  end

  def didReceiveNotification(notification)
    self.label.text = notification.request.content.body
  end

end
