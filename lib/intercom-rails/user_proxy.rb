module IntercomRails

  class UserProxy 

    POTENTIAL_USER_OBJECTS = [
      Proc.new { instance_eval &IntercomRails.config.current_user if IntercomRails.config.current_user.present? },
      Proc.new { current_user },
      Proc.new { @user }
    ]

    def self.from_current_user_in_object(search_object)
      POTENTIAL_USER_OBJECTS.each do |potential_user|
        begin
          user_proxy = new(search_object.instance_eval(&potential_user), search_object)
          return user_proxy if user_proxy.valid?
        rescue NameError
          next
        end
      end

      raise NoUserFoundError 
    end

    attr_reader :search_object, :user

    def initialize(user, search_object = nil)
      @user = user
      @search_object = search_object
    end

    def to_hash
      hsh = {}

      hsh[:user_id] = user.id if attribute_present?(:id) 
      [:email, :name, :created_at].each do |attribute|
        hsh[attribute] = user.send(attribute) if attribute_present?(attribute)
      end

      hsh[:custom_data] = custom_data
      hsh.delete(:custom_data) unless hsh[:custom_data].present?

      hsh
    end

    def custom_data
      custom_data_from_config.merge custom_data_from_request
    end

    def valid?
      return false if user.blank?
      return true if user.respond_to?(:id) && user.id.present?
      return true if user.respond_to?(:email) && user.email.present?
      false
    end

    private
    def attribute_present?(attribute)
      user.respond_to?(attribute) && user.send(attribute).present?
    end

    def custom_data_value_from_proc_or_symbol(proc_or_symbol)
      if proc_or_symbol.kind_of?(Symbol)
        user.send(proc_or_symbol)
      elsif proc_or_symbol.kind_of?(Proc)
        proc_or_symbol.call(user)
      end
    end

    def custom_data_from_request 
      search_object.intercom_custom_data
    rescue NoMethodError
      {}
    end

    def custom_data_from_config 
      return {} if Config.custom_data.blank?
      Config.custom_data.reduce({}) do |custom_data, (k,v)|
        custom_data.merge(k => custom_data_value_from_proc_or_symbol(v))
      end
    end

  end

end
