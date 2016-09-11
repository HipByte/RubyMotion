class FileProvider < NSFileProviderExtension

  def fileCoordinator
    fileCoordinator = NSFileCoordinator.alloc.init
    fileCoordinator.purposeIdentifier = self.providerIdentifier
    fileCoordinator
  end

  def init
    super
    self.fileCoordinator.coordinateWritingItemAtURL(self.documentStorageURL, options:0, error:nil, byAccessor: proc { |newURL|
      # ensure the documentStorageURL actually exists
      error = Pointer.new(:object)
      NSFileManager.defaultManager.createDirectoryAtURL(newURL, withIntermediateDirectories:true, attributes:nil, error:error)
    })
    self
  end

  def providePlaceholderAtURL(url, completionHandler:completionHandler)
    # Should call + writePlaceholderAtURL:withMetadata:error: with the placeholder URL, then call the completion handler with the error if applicable.
    fileName = url.lastPathComponent

    placeholderURL = NSFileProviderExtension.placeholderURLForURL(self.documentStorageURL.URLByAppendingPathComponent(fileName))

    # TODO: get real file size for file at url
    fileSize = 0
    metadata = { NSURLFileSizeKey => fileSize }
    NSFileProviderExtension.writePlaceholderAtURL(placeholderURL, withMetadata:metadata, error:nil)
    completionHandler.call(nil)
  end

  def startProvidingItemAtURL(url, completionHandler:completionHandler)
    # Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
    fileError = Pointer.new(:object)

    fileData = NSData.data
    # TODO: get the real contents of file at url

    fileData.writeToURL(url, options:0, error:fileError)
    completionHandler.call(nil)
  end

  def itemChangedAtURL(url)
    # Called at some point after the file has changed; the provider may then trigger an upload

    # TODO: mark file at <url> as needing an update in the model; kick off update process
    NSLog("Item changed at URL %@", url)
  end

  def stopProvidingItemAtURL(url)
    # Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
    # Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.

    NSFileManager.defaultManager.removeItemAtURL(newURL, error:nil)
    self.providePlaceholderAtURL(url, completionHandler: proc{
      # TODO: handle any error, do any necessary cleanup
    })
  end

end
