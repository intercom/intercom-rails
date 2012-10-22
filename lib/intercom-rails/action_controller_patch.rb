module IntercomRails

  module ActionControllerPatch

    include ScriptTagHelper

    CLOSING_BODY_TAG = /<\/body>/

    def render_to_body(*args)
      @rendered_string = super
      return @rendered_string unless include_intercom_javascript? 

      @rendered_string.gsub!(CLOSING_BODY_TAG, intercom_script_tag + ' \\0')
    end

    private
    def include_intercom_javascript?
      lookup_context.rendered_format == :html &&
      @rendered_string[CLOSING_BODY_TAG] &&
      user_object_present?
    end

    def user_object_present?
      !!user_object
    end

    POTENTIAL_USER_OBJECTS = [
      Proc.new { current_user },
      Proc.new { current_admin },
      Proc.new { @user },
      Proc.new { @admin }
    ]

    def user_object
      POTENTIAL_USER_OBJECTS.each do |potential_user|
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

    def intercom_script_tag
      user_details = {:app_id => ENV['INTERCOM_APP_ID']}
      user = user_object

      user_details[:user_id] = user.id if user.respond_to?(:id) && user.id.present?
      [:email, :name, :created_at].each do |attribute|
        user_details[attribute] = user.send(attribute) if user.respond_to?(attribute) && user.send(attribute).present?
      end

      super(user_details)
    end

  end 

end