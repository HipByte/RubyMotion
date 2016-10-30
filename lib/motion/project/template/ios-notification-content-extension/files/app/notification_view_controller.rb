# To send a test notification, you need to request permission first by adding
# the following snippet to the `application:didFinishLaunchingWithOptions:'
# method in your AppDelegate:
#
#   center = UNUserNotificationCenter.currentNotificationCenter
#   options = UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert
#   center.requestAuthorizationWithOptions(options, completionHandler: proc { |granted, error|
#     puts "granted notification authorization" if granted
#   })
#   center.delegate = self
#
# Then, send a test notification with:
#
#   content = UNMutableNotificationContent.alloc.init
#   content.title = "Hello World"
#   content.body = "This is a test local notification"
#   content.sound = UNNotificationSound.defaultSound
#   content.categoryIdentifier = "myNotificationCategory"
#
#   trigger = UNTimeIntervalNotificationTrigger.triggerWithTimeInterval(3.0, repeats: false)
#
#   request = UNNotificationRequest.requestWithIdentifier("some_identifier", content: content, trigger:trigger)
#   center = UNUserNotificationCenter.currentNotificationCenter
#   center.addNotificationRequest(request, withCompletionHandler: lambda do |error|
#     puts 'notification successfully sent' unless error
#   end)
#
class NotificationViewController < UIViewController
  # Enable 'IB' if you want to use storyboard.
  # extend IB

  def viewDidLoad
    self.view.backgroundColor = UIColor.redColor

    @label = UILabel.alloc.init
    @label.text = "Hello World"
    @label.textColor = UIColor.whiteColor
    @label.textAlignment = NSTextAlignmentCenter
    @label.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.view.addSubview(@label)

    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options:0, metrics:nil, views:{ "label" => label }))
    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-|", options:0, metrics:nil, views:{ "label" => label }))
  end

  def didReceiveNotification(notification)
    @label.text = notification.request.content.body
  end

end
