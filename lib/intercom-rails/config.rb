module IntercomRails

  module Config

    def self.reset!
      [self, InboxConfig].each do |configer|
        configer.instance_variables.each do |var|
          configer.send(:remove_instance_variable, var)
        end
      end
    end

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

    # Widget options
    def self.inbox
      InboxConfig
    end

    def self.custom_data=(value)
      raise ArgumentError, "custom_data should be a hash" unless value.kind_of?(Hash)
      unless value.reject { |_,v| v.kind_of?(Proc) || v.kind_of?(Symbol) }.count.zero?
        raise ArgumentError, "all custom_data attributes should be either a Proc or a symbol"
      end

      @custom_data = value
    end

    def self.custom_data
      @custom_data
    end

  end

  module InboxConfig

    def self.style=(value)
      raise ArgumentError, "inbox.style must be one of :default or :custom" unless [:default, :custom].include?(value)
      @style = value
    end

    def self.style
      @style 
    end

    def self.counter=(value)
      @counter = value
    end

    def self.counter
      @counter
    end

  end

end
