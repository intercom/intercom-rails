require 'active_support/json'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/output_safety'
require 'action_view'

module IntercomRails

  class ScriptTag

    include ::ActionView::Helpers::JavaScriptHelper

    attr_reader :user_details, :company_details, :show_everywhere
    attr_accessor :secret, :widget_options, :controller, :nonce

    def initialize(options = {})
      self.secret = options[:secret] || Config.api_secret
      self.widget_options = widget_options_from_config.merge(options[:widget] || {})
      self.controller = options[:controller]
      @show_everywhere = options[:show_everywhere]
      self.user_details = options[:find_current_user_details] ? find_current_user_details : options[:user_details]
      remove_user_cookie_on_logout if http_request?
      self.company_details = if options[:find_current_company_details]
        find_current_company_details
      elsif options[:user_details]
        options[:user_details].delete(:company) if options[:user_details]
      end
      self.nonce = options[:nonce]
    end

    def remove_user_cookie_on_logout
      if (find_current_user_details == {} && controller.response.request.cookies["intercom-session-#{IntercomRails.config.app_id}"])
        controller.response.set_cookie("intercom-session-#{IntercomRails.config.app_id}", :value => "", :expires => Time.at(0))
      end
    end

    def http_request?
      return ( defined?(controller) &&
        defined?(controller.response) &&
        defined?(controller.response.request) &&
        defined?(controller.response.set_cookie) )
    end

    def valid?
      valid = user_details[:app_id].present?
      unless @show_everywhere
        valid = valid && (user_details[:user_id] || user_details[:email]).present?
      end
      if nonce
        valid = valid && valid_nonce?
      end
      valid
    end

    def valid_nonce?
      valid = false
      if nonce
        # Base64 regexp:
        # - blocks of 4 [A-Za-z0-9+/]
        # followed either by:
        # - blocks of 2 [A-Za-z0-9+/] + '=='
        # - blocks of 3 [A-Za-z0-9+/] + '='
        base64_regexp = Regexp.new('^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$')
        m = base64_regexp.match(nonce)
        if nonce == m.to_s
          valid = true
        end
      end
      valid
    end

    def intercom_settings
      hsh = user_details
      hsh[:widget] = widget_options if widget_options.present?
      hsh[:company] = company_details if company_details.present?
      hsh
    end

    def to_s
      js_options = 'id="IntercomSettingsScriptTag"'
      if nonce && valid_nonce?
        js_options = js_options + " nonce=\"#{nonce}\""
      end
      str = "<script #{js_options}>#{intercom_javascript}</script>\n"
      str.respond_to?(:html_safe) ? str.html_safe : str
    end

    def csp_sha256
      base64_sha256 = Base64.encode64(Digest::SHA256.digest(intercom_javascript))
      csp_hash = "'sha256-#{base64_sha256}'".delete("\n")
      csp_hash
    end

    private
    def intercom_javascript
      intercom_settings_json = ActiveSupport::JSON.encode(intercom_settings).gsub('<', '\u003C')

      str = "window.intercomSettings = #{intercom_settings_json};(function(){var w=window;var ic=w.Intercom;if(typeof ic===\"function\"){ic('reattach_activator');ic('update',intercomSettings);}else{var d=document;var i=function(){i.c(arguments)};i.q=[];i.c=function(args){i.q.push(args)};w.Intercom=i;function l(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='#{Config.library_url || "https://widget.intercom.io/widget/#{j app_id}"}';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);}if(w.attachEvent){w.attachEvent('onload',l);}else{w.addEventListener('load',l,false);}};})()"

      str
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
      return user_details[:app_id] if user_details[:app_id].present?
      return IntercomRails.config.app_id if IntercomRails.config.app_id.present?
      return 'abcd1234' if defined?(Rails) && Rails.env.development?

      nil
    end

    def widget_options_from_config
      config = {}

      custom_activator = Config.inbox.custom_activator
      activator = case Config.inbox.style
      when :default
        '#IntercomDefaultWidget'
      when :custom
        custom_activator || '#Intercom'
      else
        nil
      end

      config[:activator] = activator if activator
      config
    end
  end

end
