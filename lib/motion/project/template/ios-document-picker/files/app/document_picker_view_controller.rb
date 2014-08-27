class DocumentPickerViewController < UIDocumentPickerExtensionViewController

  def openDocument(sender)
    documentURL = self.documentStorageURL.URLByAppendingPathComponent("Untitled.txt")

    # TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
    self.dismissGrantingAccessToURL(documentURL)
  end

  def prepareForPresentationInMode(mode)
    # TODO: present a view controller appropriate for picker mode here
  end

end
