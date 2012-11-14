module IntercomRails

  module Config

    # Your Intercom app_id
    def self.app_id=(value)
      @app_id = value
    end

    def self.app_id
      @app_id
    end

    # Intercom api secret, for secure mode
    def self.api_secret=(value)
      @api_secret = value
    end

    def self.api_secret
      @api_secret
    end

    # Intercom API key, for some rake tasks
    def self.api_key=(value)
      @api_key = value
    end

    def self.api_key
      @api_key
    end

    # How is the current logged in user accessed in your controllers?
    def self.current_user=(value)
      raise ArgumentError, "current_user should be a Proc" unless value.kind_of?(Proc)
      @current_user = value
    end

    def self.current_user
      @current_user
    end

    # What class defines your user model?
    def self.user_model=(value)
      raise ArgumentError, "user_model should be a Proc" unless value.kind_of?(Proc)
      @user_model = value
    end

    def self.user_model
      @user_model
    end

  end

end
