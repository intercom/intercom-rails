module IntercomRails
  module ShutdownHelper
    # This helper allows to erase cookies when a user logs out of an application
    # It is recommended to call this function every time a user logs out of your application
    # Do not use before a redirect_to because it will not clear the cookies on a redirection
    #
    # @param cookies [ActionDispatch::Cookies::CookieJar] The cookies object
    # @param domain [String] The domain used for the Intercom cookies (required).
    #   Specify the same domain that Intercom uses for its cookies
    #   (typically your main domain with a leading dot, e.g. ".yourdomain.com").
    def self.intercom_shutdown_helper(cookies, domain)      
      nil_session = { value: nil, expires: 1.day.ago }
      
      unless domain == 'localhost'
        dotted_domain = domain.start_with?('.') ? domain : ".#{domain}"
        nil_session = nil_session.merge(domain: dotted_domain)
      end

      cookies["intercom-session-#{IntercomRails.config.app_id}"] = nil_session
    rescue => e
      Rails.logger.error("Error in intercom_shutdown_helper: #{e.message}") if defined?(Rails) && Rails.logger
    end

    def self.prepare_intercom_shutdown(session)
      session[:perform_intercom_shutdown] = true
    end

    def self.intercom_shutdown(session, cookies, domain)
      if session[:perform_intercom_shutdown]
        session.delete(:perform_intercom_shutdown)
        intercom_shutdown_helper(cookies, domain)
      end
    end

  end
end
