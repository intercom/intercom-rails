require "active_support/json"
require "active_support/core_ext/hash/indifferent_access"

module IntercomRails

  class ScriptTag

    def self.generate(*args)
      new(*args).output
    end

    attr_reader :user, :secret, :widget_options
    def initialize(user_details, options = {})
      @secret = options[:secret] || Config.api_secret
      @widget_options = options[:widget] || widget_options_from_config

      @user = user_details.with_indifferent_access
      @user[:user_hash] = user_hash if secret.present?
      [:email, :name, :user_id].each { |key| @user.delete(key) if @user[key].nil? }
    end

    def intercom_settings
      return @intercom_settings if @intercom_settings.present?
      
      @intercom_settings = user.merge(:widget => widget_options)
      @intercom_settings = convert_dates_to_unix_timestamps(@intercom_settings)
    end

    def output 
      str = <<-INTERCOM_SCRIPT
<script id="IntercomSettingsScriptTag">
  var intercomSettings = #{ActiveSupport::JSON.encode(intercom_settings)};
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

      str.respond_to?(:html_safe) ? str.html_safe : str
    end

    private
    def user_hash
      components = [secret, (user[:user_id] || user[:email])]
      Digest::SHA1.hexdigest(components.join)
    end

    def widget_options_from_config 
      return nil unless Config.inbox

      activator = case Config.inbox
      when :default
        '#IntercomDefaultWidget'
      when :custom
        '#Intercom'
      end

      {:activator => activator}
    end

    def convert_dates_to_unix_timestamps(object)
      return Hash[object.map { |k, v| [k, convert_dates_to_unix_timestamps(v)] }] if object.is_a?(Hash)
      return object.strftime('%s').to_i if object.respond_to?(:strftime)
      object
    end

  end

end
