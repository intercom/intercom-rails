require 'active_support/json'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/output_safety'

module IntercomRails

  class ScriptTag

    def self.generate(*args)
      new(*args).output
    end

    attr_reader :user_details, :company_details, :show_everywhere
    attr_accessor :secret, :widget_options, :controller

    def initialize(options = {})
      self.secret = options[:secret] || Config.api_secret
      self.widget_options = widget_options_from_config.merge(options[:widget] || {})
      self.controller = options[:controller]
      @show_everywhere = options[:show_everywhere]
      self.user_details = options[:find_current_user_details] ? find_current_user_details : options[:user_details]
      self.company_details = if options[:find_current_company_details]
        find_current_company_details
      elsif options[:user_details]
        options[:user_details].delete(:company) if options[:user_details]
      end
    end

    def valid?
      valid = user_details[:app_id].present?
      unless @show_everywhere
        valid = valid && (user_details[:user_id] || user_details[:email]).present?
      end
      valid
    end

    def intercom_settings
      hsh = user_details
      hsh[:widget] = widget_options if widget_options.present?
      hsh[:company] = company_details if company_details.present?
      hsh
    end

    def output
      intercom_settings_json = ActiveSupport::JSON.encode(intercom_settings).gsub('<', '\u003C')

      str = <<-INTERCOM_SCRIPT
<script id="IntercomSettingsScriptTag">
  window.intercomSettings = #{intercom_settings_json};
</script>
<script>(function(){var w=window;var ic=w.Intercom;if(typeof ic==="function"){ic('reattach_activator');ic('update',intercomSettings);}else{var d=document;var i=function(){i.c(arguments)};i.q=[];i.c=function(args){i.q.push(args)};w.Intercom=i;function l(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='#{Config.library_url || "https://widget.intercom.io/widget/#{app_id}"}';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);}if(w.attachEvent){w.attachEvent('onload',l);}else{w.addEventListener('load',l,false);}};})()</script>
      INTERCOM_SCRIPT

      str.respond_to?(:html_safe) ? str.html_safe : str
    end

    private
    def user_details=(user_details)
      @user_details = DateHelper.convert_dates_to_unix_timestamps(user_details || {})
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

    def company_details=(company_details)
      @company_details = DateHelper.convert_dates_to_unix_timestamps(company_details || {})
      @company_details = @company_details.with_indifferent_access.tap do |c|
        [:id, :name].each { |k| c.delete(k) if c[k].nil? }
      end
    end

    def find_current_company_details
      return {} unless controller.present?
      Proxy::Company.current_in_context(controller).to_hash
    rescue NoCompanyFoundError
      {}
    end

    def user_hash
      OpenSSL::HMAC.hexdigest("sha256", secret, (user_details[:user_id] || user_details[:email]).to_s)
    end

    def app_id
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
      config
    end
  end

end
