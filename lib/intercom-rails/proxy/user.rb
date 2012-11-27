module IntercomRails

  module Proxy

    class User < Proxy

      POTENTIAL_USER_OBJECTS = [
        Proc.new { instance_eval &IntercomRails.config.user.current if IntercomRails.config.user.current.present? },
        Proc.new { current_user },
        Proc.new { @user }
      ]

      def standard_data
        hsh = {}

        hsh[:user_id] = user.id if attribute_present?(:id) 
        [:email, :name, :created_at].each do |attribute|
          hsh[attribute] = user.send(attribute) if attribute_present?(attribute)
        end

        hsh
      end

      def valid?
        return true if user.respond_to?(:id) && user.id.present?
        return true if user.respond_to?(:email) && user.email.present?
        false
      end

    end

  end

end
