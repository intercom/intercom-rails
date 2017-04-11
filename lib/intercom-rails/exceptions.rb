module IntercomRails

  class Error < StandardError; end
  class NoUserFoundError < Error; end
  class ExcludedUserFoundError < Error; end
  class NoCompanyFoundError < Error; end

end
