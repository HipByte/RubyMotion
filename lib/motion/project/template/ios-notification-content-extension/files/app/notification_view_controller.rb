class NotificationViewController

  def viewDidLoad
  end

  def didReceiveNotification(notification)
    self.label.text = notification.request.content.body
  end

end
