require 'action_controller'

module IntercomRails

  module ActionControllerPatch

    include ScriptTagHelper

    CLOSING_BODY_TAG = %r{</body>}

    ActionController::Base.after_filter :modify_response_to_insert_intercom_script_tag

    def modify_response_to_insert_intercom_script_tag
      return unless include_intercom_javascript?
      response.body = response.body.gsub(CLOSING_BODY_TAG, intercom_script_tag + '\\0')
    end

    def intercom_script_tag_called!
      @intercom_script_tag_called = true
    end

    private
    def include_intercom_javascript?
      intercom_app_id.present? &&
      !@intercom_script_tag_called &&
      (response.content_type == 'text/html') &&
      response.body[CLOSING_BODY_TAG] &&
      intercom_user_object.present?
    end

    POTENTIAL_INTERCOM_USER_OBJECTS = [
      Proc.new { current_user },
      Proc.new { @user }
    ]

    def intercom_user_object
      POTENTIAL_INTERCOM_USER_OBJECTS.each do |potential_user|
        begin
          user = instance_eval &potential_user
          return user if user.present? && 
                         (user.email.present? || user.id.present?)
        rescue NameError
          next
        end
      end

      nil
    end

    def intercom_app_id
      return ENV['INTERCOM_APP_ID'] if ENV['INTERCOM_APP_ID'].present?
      return 'abcd1234' if defined?(Rails) && Rails.env.development?
      nil
    end

    def intercom_script_tag
      user_details = {:app_id => intercom_app_id}
      user = intercom_user_object

      user_details[:user_id] = user.id if user.respond_to?(:id) && user.id.present?
      [:email, :name, :created_at].each do |attribute|
        user_details[attribute] = user.send(attribute) if user.respond_to?(attribute) && user.send(attribute).present?
      end

      super(user_details)
    end

  end 

end
