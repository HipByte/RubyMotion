class IndexRequestHandler < CSIndexExtensionRequestHandler

  def searchableIndex(searchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler:acknowledgementHandler)
    # Reindex all data with the provided index

    acknowledgementHandler.call
  end

  def searchableIndex(searchableIndex, reindexSearchableItemsWithIdentifiers:identifiers, acknowledgementHandler:acknowledgementHandler)
    # Reindex any items with the given identifiers and the provided index

    acknowledgementHandler.call
  end

end
