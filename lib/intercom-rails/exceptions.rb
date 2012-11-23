module IntercomRails

  class Error < StandardError; end
  
  class NoUserFoundError < Error; end
  class ImportError < Error; end
  class IntercomAPIError < Error; end

end
