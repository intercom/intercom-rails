module IntercomRails

  class AutoIncludeFilter

    include ScriptTagHelper
    CLOSING_BODY_TAG = %r{</body>}

    def self.filter(controller)
      auto_include_filter = new(controller)
      return unless auto_include_filter.include_javascript?

      auto_include_filter.include_javascript!
    end

    attr_reader :controller

    def initialize(kontroller)
      @controller = kontroller 
    end

    def include_javascript! 
      response.body = response.body.gsub(CLOSING_BODY_TAG, intercom_script_tag + '\\0')
    end

    def include_javascript?
      !intercom_script_tag_called_manually? &&
      html_content_type? &&
      response_has_closing_body_tag? &&
      intercom_app_id.present? &&
      intercom_user_object.present?
    end

    private
    def response
      controller.response
    end

    def html_content_type?
      response.content_type == 'text/html'
    end

    def response_has_closing_body_tag?
      !!(response.body[CLOSING_BODY_TAG])
    end

    def intercom_script_tag_called_manually?
      controller.instance_variable_get(SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE)
    end

    POTENTIAL_INTERCOM_USER_OBJECTS = [
      Proc.new { instance_eval &IntercomRails.config.current_user if IntercomRails.config.current_user.present? },
      Proc.new { current_user },
      Proc.new { @user }
    ]

    def intercom_user_object
      POTENTIAL_INTERCOM_USER_OBJECTS.each do |potential_user|
        begin
          user = controller.instance_eval &potential_user
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
      return IntercomRails.config.app_id if IntercomRails.config.app_id.present?
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
