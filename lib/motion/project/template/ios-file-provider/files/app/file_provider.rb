class FileProvider < NSFileProviderExtension

  def fileCoordinator
    fileCoordinator = NSFileCoordinator.alloc.init
    fileCoordinator.setPurposeIdentifier(self.providerIdentifier)
    fileCoordinator
  end

  def init
    super
    self.fileCoordinator.coordinateWritingItemAtURL(self.documentStorageURL, options:0, error:nil, byAccessor: proc { |newURL|
        error = Pointer.new(:object)
        NSFileManager.defaultManager.createDirectoryAtURL(newURL, withIntermediateDirectories(true, attributes:nil, error:error))
    }.weak!)
    self
  end

  def providePlaceholderAtURL(url, completionHandler:completionHandler)
    # Should call + createPlaceholderWithMetadata:atURL: with the placeholder URL, then call the completion handler with that URL.
    fileName = url.lastPathComponent

    placeholderURL = NSFileProviderExtension.placeholderURLForURL(self.documentStorageURL.URLByAppendingPathComponent(fileName))

    fileSize = 0
    # TODO: get file size for file at <url> from model

    self.fileCoordinator.coordinateWritingItemAtURL(placeholderURL, options:0, error:nil, byAccessor: proc { |error|
        metadata = { NSURLFileSizeKey => fileSize }
        NSFileProviderExtension.writePlaceholderAtURL(placeholderURL, withMetadata:metadata, error:nil)
    }.weak!)

    completionHandler.call(nil) if completionHandler
  end

  def startProvidingItemAtURL(url, completionHandler:completionHandler)
    # Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
    error = Pointer.new(:object)
    fileError = Pointer.new(:object)

    fileData = NSData.data
    # TODO: get the contents of file at <url> from model

    self.fileCoordinator.coordinateWritingItemAtURL(url, options:0, error:error, byAccessor: proc { |newURL|
        fileData.writeToURL(newURL, options(0, error:fileError))
    })
    if error
      completionHandler.call(error)
    else
      completionHandler.call(fileError)
    end
  end

  def itemChangedAtURL(url)
    # Called at some point after the file has changed; the provider may then trigger an upload

    # TODO: mark file at <url> as needing an update in the model; kick off update process
    NSLog("Item changed at URL %@", url)
  end

  def stopProvidingItemAtURL(url)
    # Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
    # Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.

    self.fileCoordinator.coordinateWritingItemAtURL(url, options:NSFileCoordinatorWritingForDeleting, error:nil, byAccessor: proc { |newURL|
      NSFileManager.defaultManager.removeItemAtURL(newURL, error:nil)
    })
    self.providePlaceholderAtURL(url, completionHandler:nil)
  end

end
