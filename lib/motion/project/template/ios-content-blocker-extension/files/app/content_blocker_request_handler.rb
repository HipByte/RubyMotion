class ContentBlockerRequestHandler

  def beginRequestWithExtensionContext(context)
    attachment = NSItemProvider.alloc.initWithContentsOfURL(NSBundle.mainBundle.URLForResource("blockerList", withExtension:"json"))

    item = NSExtensionItem.new
    item.attachments = [attachment]

    context.completeRequestReturningItems([item], completionHandler:nil)
  end

end
