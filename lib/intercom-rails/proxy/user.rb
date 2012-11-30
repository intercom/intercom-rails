module IntercomRails

  module Proxy

    class User < Proxy

      POTENTIAL_USER_OBJECTS = [
        Proc.new { instance_eval &IntercomRails.config.user.current if IntercomRails.config.user.current.present? },
        Proc.new { current_user },
        Proc.new { @user }
      ]

      def self.current_in_context(search_object)
        POTENTIAL_USER_OBJECTS.each do |potential_object|
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
        hsh = {}

        hsh[:user_id] = user.id if attribute_present?(:id) 
        [:email, :name, :created_at].each do |attribute|
          hsh[attribute] = user.send(attribute) if attribute_present?(attribute)
        end

        hsh
      end

      def valid?
        return false if user.blank? || user.respond_to?(:new_record?) && user.new_record?
        return true if user.respond_to?(:id) && user.id.present?
        return true if user.respond_to?(:email) && user.email.present?
        false
      end

    end

  end

end
