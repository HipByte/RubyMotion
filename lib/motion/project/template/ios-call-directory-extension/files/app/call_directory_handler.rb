class CallDirectoryHandler < CXCallDirectoryProvider

  def beginRequestWithExtensionContext(context)
    context.delegate = self

    if !self.addBlockingPhoneNumbersToContext(context)
      NSLog("Unable to add blocking phone numbers")
      error = NSError.errorWithDomain("CallDirectoryHandler", code:1, userInfo:nil)
      context.cancelRequestWithError(error)
      return
    end

    if !self.addIdentificationPhoneNumbersToContext(context)
      NSLog("Unable to add identification phone numbers")
      error = NSError.errorWithDomain("CallDirectoryHandler", code:2, userInfo:nil)
      context.cancelRequestWithError(error)
      return
    end

    context.completeRequestWithCompletionHandler(nil)
  end

  def addBlockingPhoneNumbersToContext(context)
    # Retrieve phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
    # consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.

    # Numbers must be provided in numerically ascending order.
    (14_085_555_555..18_005_555_555).each do |phone_number|
      context.addBlockingEntryWithNextSequentialPhoneNumber(phone_number)
    end

    true
  end

  def addIdentificationPhoneNumbersToContext(context)
    # Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
    # consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.

    # Numbers must be provided in numerically ascending order.
    labels = ["Telemarketer", "Local business"]

    (18_775_555_555..18_885_555_555).each do |phone_number|
      context.addIdentificationEntryWithNextSequentialPhoneNumber(phone_number, label:labels.take)
    end

    true
  end

  # CXCallDirectoryExtensionContextDelegate

  def requestFailedForExtensionContext(extensionContext, withError:error)
    # An error occurred while adding blocking or identification entries, check the NSError for details.
    # For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
    #
    # This may be used to store the error details in a location accessible by the extension's containing app, so that the
    # app may be notified about errors which occured while loading data even if the request to load data was initiated by
    # the user in Settings instead of via the app itself.
  end

end
