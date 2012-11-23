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
          user = search_object.instance_eval &potential_user
          return new(user) if user.present? && 
                              (user.email.present? || user.id.present?)
        rescue NameError
          next
        end
      end

      raise NoUserFoundError 
    end

    attr_reader :search_object, :user

    def initialize(user)
      @user = user
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
      return {} unless Config.custom_data.present?
      Config.custom_data.reduce({}) do |custom_data, (k,v)|
        custom_data.merge(k => custom_data_value_from_proc_or_symbol(v))
      end
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

  end

end
