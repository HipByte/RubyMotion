class NotificationService < UNNotificationServiceExtension

  def didReceiveNotificationRequest(request, withContentHandler:contentHandler)
    @contentHandler = contentHandler
    @bestAttemptContent = request.content.mutableCopy

    # Modify the notification content here...
    @bestAttemptContent.title = "#{@bestAttemptContent.title} [modified]"

    @contentHandler.call(@bestAttemptContent)
  end

  def serviceExtensionTimeWillExpire
    # Called just before the extension will be terminated by the system.
    # Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    @contentHandler.call(@bestAttemptContent)
  end

end
