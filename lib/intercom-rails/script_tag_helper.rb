require "active_support/json"
require "active_support/core_ext/hash/indifferent_access"

module IntercomRails
  # Helper methods for generating Intercom javascript script tags.
  module ScriptTagHelper
    # @param user_details [Hash] a customizable hash of user details
    # @param widget_options [Hash] an optional hash for widget customisation
    # @option user_details [String] :app_id Your application id (get it here)
    # @option user_details [String] :user_id unique id of this user within your application
    # @option user_details [String] :email email address for this user
    # @option user_details [String] :name the users name, _optional_ but useful for identify people in the Intercom App.
    # @option user_details [Hash] :custom_data custom attributes you'd like saved for this user on Intercom. See
    # @option widget_options [String] :activator a css selector for an element which when clicked should show the Intercom widget
    # @return [String] Intercom script tag
    # @example basic example
    #   <%= intercom_script_tag({ :app_id => "your-app-id",
    #                             :user_id => current_user.id,
    #                             :email => current_user.email,
    #                             :custom_data => { :plan => current_user.plan.name },
    #                             :name => current_user.name }
    #                           ) %>
    # @example with widget activator for launching then widget when an element matching the css selector '#Intercom' is clicked.
    #   <%= intercom_script_tag({ :app_id => "your-app-id",
    #                             :user_id => current_user.id,
    #                             :email => current_user.email,
    #                             :custom_data => { :plan => current_user.plan.name },
    #                             :name => current_user.name }
    #                             {:activator => "#Intercom"}
    #                          ) %>
    def intercom_script_tag(user_details, widget_options={})
      intercom_settings = user_details.merge({:widget => widget_options}).with_indifferent_access
      intercom_settings_with_dates_as_timestamps = convert_dates_to_unix_timestamps(intercom_settings)
      intercom_settings_with_dates_as_timestamps.reject! { |key, value| %w(email name user_id).include?(key.to_s) && value.nil? }
      intercom_script = <<-INTERCOM_SCRIPT
<script id="IntercomSettingsScriptTag">
    var intercomSettings = #{ActiveSupport::JSON.encode(intercom_settings_with_dates_as_timestamps)};
</script>
<script>
(function() {
  function async_load() {
    var s = document.createElement('script');
    s.type = 'text/javascript'; s.async = true;
    s.src = 'https://api.intercom.io/api/js/library.js';
    var x = document.getElementsByTagName('script')[0];
    x.parentNode.insertBefore(s, x);
  }
  if (window.attachEvent) {
    window.attachEvent('onload', async_load);
  } else {
    window.addEventListener('load', async_load, false);
  }
})();
</script>
      INTERCOM_SCRIPT
      intercom_script.respond_to?(:html_safe) ? intercom_script.html_safe : intercom_script
    end

    private
    def convert_dates_to_unix_timestamps(object)
      return Hash[object.map { |k, v| [k, convert_dates_to_unix_timestamps(v)] }] if object.is_a?(Hash)
      return object.strftime('%s').to_i if object.respond_to?(:strftime)
      object
    end
  end
end