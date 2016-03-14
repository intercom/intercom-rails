module IntercomRails
  module ShutdownHelper
    # This helper allows to erase cookies when a user log out of an application
    # It is recommanded to call this function every time a user log out of your application
    # specifically if you use both "Acquire" and another Intercom product
    # Do not use before a redirect_to because it will not clear the cookies on a redirection
    def self.intercom_shutdown_helper (controller)
      controller.response.delete_cookie("intercom-session-#{IntercomRails.config.app_id}")
    end
  end
end
