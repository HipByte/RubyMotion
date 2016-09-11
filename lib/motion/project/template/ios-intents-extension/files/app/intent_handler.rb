# As an example, this class is set up to handle Message intents.
# You will want to replace this or add other intents as appropriate.
# The intents you wish to handle must be declared in the extension's Rakefile.
#
# You can test your example integration by saying things to Siri like:
# "Send a message using <myApp>"
# "<myApp> John saying hello"
# "Search for messages in <myApp>"

class IntentHandler < INExtension

  def handlerForIntent(intent)
    # This is the default implementation. If you want different objects to handle different intents,
    # you can override this and return the handler you want for that particular intent.
    self
  end

  # INSendMessageIntentHandling

  # Implement resolution methods to provide additional information about your intent (optional).
  def resolveRecipientsForSendMessage(intent, withCompletion:completion)
    recipients = intent.recipients
    # If no recipients were provided we'll need to prompt for a value.
    if recipients.empty?
      completion.call([INPersonResolutionResult.needsValue])
      return
    end
    resolutionResults = []

    recipients.each do |recipient|
        matchingContacts = [recipient]
        # Implement your contact matching logic here to create an array of matching contacts
        if matchingContacts.count > 1
          # We need Siri's help to ask user to pick one from the matches.
          resolutionResults << INPersonResolutionResult.disambiguationWithPeopleToDisambiguate(matchingContacts)
        elsif matchingContacts.count == 1
          # We have exactly one matching contact
          resolutionResults << INPersonResolutionResult.successWithResolvedPerson(recipient)
        else
          # We have no contacts matching the description provided
          resolutionResults << INPersonResolutionResult.unsupported
        end
    end
    completion.call(resolutionResults)
  end

  def resolveContentForSendMessage(intent, withCompletion:completion)
    text = intent.content
    if text && !text.empty?
      completion.call(INStringResolutionResult.successWithResolvedString(text))
    else
      completion.call(INStringResolutionResult.needsValue)
    end
  end

  # Once resolution is completed, perform validation on the intent and provide confirmation (optional).

  def confirmSendMessage(intent, completion:completion)
    # Verify user is authenticated and your app is ready to send a message.
    userActivity = NSUserActivity.alloc.initWithActivityType(NSStringFromClass(INSendMessageIntent))
    response = INSendMessageIntentResponse.alloc.initWithCode(INSendMessageIntentResponseCodeReady, userActivity:userActivity)
    completion.call(response);
  end

  # Handle the completed intent (required).

  def handleSendMessage(intent, completion:completion)
    # Implement your application logic to send a message here.
    userActivity = NSUserActivity.alloc.initWithActivityType(NSStringFromClass(INSendMessageIntent))
    response = INSendMessageIntentResponse.alloc.initWithCode(INSendMessageIntentResponseCodeSuccess, userActivity:userActivity)
    completion.call(response);
  end

  # Implement handlers for each intent you wish to handle.  As an example for messages, you may wish to also handle searchForMessages and setMessageAttributes.

  # INSearchForMessagesIntentHandling

  def handleSearchForMessages(intent, completion:completion)
    # Implement your application logic to find a message that matches the information in the intent.

    userActivity = NSUserActivity.alloc.initWithActivityType(NSStringFromClass(INSearchMessageIntent))
    response = INSearchMessageIntentResponse.alloc.initWithCode(INSearchMessageIntentResponseCodeSuccess, userActivity:userActivity)
    # Initialize with found message's attributes
    response.messages = INMessage.alloc.initWithIdentifier("identifier",
      content:"I am so excited about SiriKit!",
      dateSent:NSDate.date,
      sender:INPerson.alloc.initWithPersonHandle(INPersonHandle.alloc.initWithValue("sarah@example.com", type:INPersonHandleTypeEmailAddress), nameComponents:nil, displayName:"Sarah", image:nil, contactIdentifier:nil, customIdentifier:nil),
      recipients:INPerson.alloc.initWithPersonHandle(INPersonHandle.alloc.initWithValue("+1-415-555-5555", type:INPersonHandleTypePhoneNumber), nameComponents:nil, displayName:"John", image:nil, contactIdentifier:nil, customIdentifier:nil))
    completion.call(response)
  end

  # INSetMessageAttributeIntentHandling

  def handleSetMessageAttribute(intent, completion:completion)
    # Implement your application logic to set the message attribute here.
    userActivity = NSUserActivity.alloc.initWithActivityType(NSStringFromClass(INSetMessageAttributeIntent))
    response = INSetMessageAttributeIntentResponse.alloc.initWithCode(INSetMessageAttributeIntentResponseCodeSuccess, userActivity:userActivity)
    completion.call(response)
  end

end
