module IntercomRails

  class Error < StandardError; end
  class ImportError < Error; end
  class IntercomAPIError < Error; end
  class NoUserFoundError < Error; end
  class NoCompanyFoundError < Error; end

end
