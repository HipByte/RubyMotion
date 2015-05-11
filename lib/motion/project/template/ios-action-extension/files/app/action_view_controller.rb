class ActionViewController < UIViewController

  attr_accessor :imageView

  def initWithNibName(nibNameOrNil, bundle:nibBundleOrNil)
    super
    self
  end

  def viewDidLoad
    super

    # Get the item[s] we're handling from the extension context.

    # For example, look for an image and place it into an image view.
    # Replace this with something appropriate for the type[s] your extension supports.
    imageFound = false
    self.extensionContext.inputItems.each do |item|
      item.attachments.each do |itemProvider|
        if itemProvider.hasItemConformingToTypeIdentifier(KUTTypeImage)
          # This is an image. We'll load it, then place it in our image view.
          imageView = WeakRef.new(self.imageView)
          itemProvider.loadItemForTypeIdentifier(KUTTypeImage, options:nil, completionHandler: proc { |url, error|
            if url
              image = UIImage.alloc.initWithData(NSData.dataWithContentsOfURL(url))
              NSOperationQueue.mainQueue.addOperationWithBlock(proc {
                imageView.setImage(image)
              })
            end
          })

          imageFound = true
          break
        end
      end

      break if imageFound
    end
  end

  def didReceiveMemoryWarning
    super
    # Dispose of any resources that can be recreated.
  end

  def done
    # Return any edited content to the host app.
    # This template doesn't do anything, so we just echo the passed in items.
    self.extensionContext.completeRequestReturningItems(self.extensionContext.inputItems, completionHandler:nil)
  end

end
