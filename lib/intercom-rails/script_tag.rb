require "active_support/json"
require "active_support/core_ext/hash/indifferent_access"

module IntercomRails

  class ScriptTag

    def self.generate(*args)
      new(*args).output
    end

    attr_reader :user_details
    attr_accessor :secret, :widget_options, :controller

    def initialize(options = {})
      self.secret = options[:secret] || Config.api_secret
      self.widget_options = widget_options_from_config.merge(options[:widget] || {})
      self.controller = options[:controller]
      self.user_details = options[:find_current_user_details] ? find_current_user_details : options[:user_details] 
    end

    def valid?
      user_details[:app_id].present? && (user_details[:user_id] || user_details[:email]).present?
    end

    def intercom_settings
      options = {}
      options[:widget] = widget_options if widget_options.present?

      user_details.merge(options)
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
    def user_details=(user_details)
      @user_details = convert_dates_to_unix_timestamps(user_details || {})
      @user_details = @user_details.with_indifferent_access.tap do |u|
        [:email, :name, :user_id].each { |k| u.delete(k) if u[k].nil? }

        u[:user_hash] ||= user_hash if secret.present? && (u[:user_id] || u[:email]).present?
        u[:app_id] ||= app_id
      end
    end

    def find_current_user_details
      return {} unless controller.present?
      Proxy::User.current_in_context(controller).to_hash
    rescue NoUserFoundError 
      {}
    end

    def user_hash
      components = [secret, (user_details[:user_id] || user_details[:email])]
      Digest::SHA1.hexdigest(components.join)
    end

    def app_id
      return ENV['INTERCOM_APP_ID'] if ENV['INTERCOM_APP_ID'].present?
      return IntercomRails.config.app_id if IntercomRails.config.app_id.present?
      return 'abcd1234' if defined?(Rails) && Rails.env.development?

      nil
    end

    def widget_options_from_config 
      config = {}

      activator = case Config.inbox.style
      when :default
        '#IntercomDefaultWidget'
      when :custom
        '#Intercom'
      else
        nil
      end

      config[:activator] = activator if activator
      config[:use_counter] = Config.inbox.counter if Config.inbox.counter

      config
    end

    def convert_dates_to_unix_timestamps(object)
      return Hash[object.map { |k, v| [k, convert_dates_to_unix_timestamps(v)] }] if object.is_a?(Hash)
      return object.strftime('%s').to_i if object.respond_to?(:strftime)
      object
    end

  end

end
