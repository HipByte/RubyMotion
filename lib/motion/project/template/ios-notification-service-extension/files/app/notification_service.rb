class NotificationService < UNNotificationServiceExtension

  attr_accessor :contentHandler, :bestAttemptContent

  def didReceiveNotificationRequest(request, withContentHandler:contentHandler)
    self.contentHandler = contentHandler
    self.bestAttemptContent = request.content.mutableCopy

    # Modify the notification content here...
    self.bestAttemptContent.title = "#{self.bestAttemptContent.title} [modified]"

    self.contentHandler.call(self.bestAttemptContent)
  end

  def serviceExtensionTimeWillExpire
    # Called just before the extension will be terminated by the system.
    # Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler.call(self.bestAttemptContent)
  end

end
