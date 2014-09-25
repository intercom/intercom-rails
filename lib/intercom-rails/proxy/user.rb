module IntercomRails

  module Proxy

    class User < Proxy

      proxy_delegator :id, :identity => true
      proxy_delegator :email, :identity => true
      proxy_delegator :name
      proxy_delegator :created_at

      PREDEFINED_POTENTIAL_USER_OBJECTS = [
        Proc.new { current_user },
        Proc.new { @user }
      ]

      def self.potential_user_objects
        if config.current.present?
          [Proc.new { instance_eval &IntercomRails.config.user.current }]
        else
          PREDEFINED_POTENTIAL_USER_OBJECTS
        end
      end

      def self.current_in_context(search_object)
        potential_user_objects.each do |potential_object|
          begin
            user_proxy = new(search_object.instance_eval(&potential_object), search_object)
            return user_proxy if user_proxy.valid?
          rescue NameError
            next
          end
        end

        raise NoUserFoundError
      end

      def standard_data
        super.tap do |hsh|
          hsh[:user_id] = hsh.delete(:id) if hsh.has_key?(:id)
        end
      end

      def valid?
        return false if user.blank? || user.respond_to?(:new_record?) && user.new_record?
        return false if config.user.exclude_if.present? && config.user.exclude_if.call(user)
        identity_present?
      end

    end

  end

end
