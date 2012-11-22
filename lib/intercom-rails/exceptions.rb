module IntercomRails

  class Error < StandardError; end
  
  class CurrentUserNotFoundError < Error; end
  class ImportError < Error; end
  class IntercomAPIError < Error; end

end
