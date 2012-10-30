module IntercomRails

  module Config

    def self.app_id=(value)
      @@app_id = value
    end

    def self.app_id
      @@app_id
    end

    def self.current_user=(value)
      raise ArgumentError, "current_user should be a Proc" unless value.kind_of?(Proc)
      @@current_user = value
    end

    def self.current_user
      @@current_user
    end

  end

end
