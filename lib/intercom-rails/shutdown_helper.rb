module IntercomRails
  module ShutdownHelper
    # This helper allows to erase cookies when a user log out of an application
    # It is recommanded to call this function every time a user log out of your application
    # Do not use before a redirect_to because it will not clear the cookies on a redirection
    def self.intercom_shutdown_helper(cookies, domain = nil)
      if (cookies.is_a?(ActionDispatch::Cookies::CookieJar))
        cookies["intercom-session-#{IntercomRails.config.app_id}"] = { value: nil, expires: 1.day.ago }.merge(domain.present? ? { domain: ".#{domain}"} : {})
      else
        controller = cookies
        Rails.logger.info("Warning: IntercomRails::ShutdownHelper.intercom_shutdown_helper takes an instance of ActionDispatch::Cookies::CookieJar as an argument since v0.2.34. Passing a controller is depreciated. See https://github.com/intercom/intercom-rails#shutdown for more details.")
        controller.response.delete_cookie("intercom-session-#{IntercomRails.config.app_id}", { value: nil, expires: 1.day.ago }).merge(domain.present? ? { domain: ".#{domain}"} : {})
      end
    rescue
    end

    def self.prepare_intercom_shutdown(session)
      session[:perform_intercom_shutdown] = true
    end

    def self.intercom_shutdown(session, cookies, domain = nil)
      if session[:perform_intercom_shutdown]
        session.delete(:perform_intercom_shutdown)
        intercom_shutdown_helper(cookies, domain)
      end
    end

  end
end
