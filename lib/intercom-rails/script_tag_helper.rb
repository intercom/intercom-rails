module IntercomRails
  SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE = :@_intercom_script_tag_helper_called

  module ScriptTagHelper
    # Generate an intercom script tag.
    #
    # @param user_details [Hash] a customizable hash of user details
    # @param options [Hash] an optional hash for secure mode and widget customisation
    # @option user_details [String] :app_id Your application id
    # @option user_details [String] :user_id unique id of this user within your application
    # @option user_details [String] :email email address for this user
    # @option user_details [String] :name the users name, _optional_ but useful for identify people in the Intercom App.
    # @option user_details [Hash] :custom_data custom attributes you'd like saved for this user on Intercom.
    # @option options [String] :widget a hash containing a css selector for an element which when clicked should show the Intercom widget
    # @option options [String] :secret Your app secret for secure mode
    # @return [String] Intercom script tag
    # @example basic example
    #   <%= intercom_script_tag({ :app_id => "your-app-id",
    #                             :user_id => current_user.id,
    #                             :email => current_user.email,
    #                             :custom_data => { :plan => current_user.plan.name },
    #                             :name => current_user.name }) %>
    # @example with widget activator for launching then widget when an element matching the css selector '#Intercom' is clicked.
    #   <%= intercom_script_tag({ :app_id => "your-app-id",
    #                             :user_id => current_user.id,
    #                             :email => current_user.email,
    #                             :custom_data => { :plan => current_user.plan.name },
    #                             :name => current_user.name },
    #                             {:widget => {:activator => "#Intercom"}},) %>
    def intercom_script_tag(user_details = nil, options={})
      controller.instance_variable_set(IntercomRails::SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE, true) if defined?(controller)
      options[:user_details] = user_details if user_details.present?
      options[:find_current_user_details] = !options[:user_details]
      options[:find_current_company_details] = !(options[:user_details] && options[:user_details][:company])
      options[:controller] = controller if defined?(controller)

      ScriptTag.generate(options)
    end
  end
end
