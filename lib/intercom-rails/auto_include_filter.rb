module IntercomRails

  module AutoInclude
    module Method
      def intercom_rails_auto_include
        IntercomRails::AutoInclude::Filter.filter(self)
      end
    end

    class Filter

      CLOSING_BODY_TAG = %r{</body>}
      BLACKLISTED_CONTROLLER_NAMES = ["Devise::PasswordsController"]

      def self.filter(controller)
        return if BLACKLISTED_CONTROLLER_NAMES.include?(controller.class.name)
        auto_include_filter = new(controller)
        return unless auto_include_filter.include_javascript?

        auto_include_filter.include_javascript!

        # User defined method to whitelist the script sha-256 when using CSP
        if defined?(CoreExtensions::IntercomRails::AutoInclude.csp_sha256_hook) == 'method'
          CoreExtensions::IntercomRails::AutoInclude.csp_sha256_hook(controller, auto_include_filter.csp_sha256)
        end
      end

      attr_reader :controller

      def initialize(kontroller)
        @controller = kontroller
      end

      def include_javascript!
        split = response.body.split("</body>")
        response.body = split.first + intercom_script_tag.to_s + "</body>" + split.last
      end

      def include_javascript?
        enabled_for_environment? &&
        !intercom_script_tag_called_manually? &&
        html_content_type? &&
        response_has_closing_body_tag? &&
        intercom_script_tag.valid?
      end

      def csp_sha256
        intercom_script_tag.csp_sha256
      end

      private
      def response
        controller.response
      end

      def html_content_type?
        response.content_type == 'text/html'
      end

      def response_has_closing_body_tag?
        !!(response.body[CLOSING_BODY_TAG])
      end

      def intercom_script_tag_called_manually?
        controller.instance_variable_get(SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE)
      end

      def intercom_script_tag
        options = {
          :find_current_user_details => true,
          :find_current_company_details => true,
          :controller => controller,
          :show_everywhere => show_everywhere?
        }
        # User defined method for applying a nonce to the inserted js tag when
        # using CSP
        if defined?(CoreExtensions::IntercomRails::AutoInclude.csp_nonce_hook) == 'method'
          nonce = CoreExtensions::IntercomRails::AutoInclude.csp_nonce_hook(controller)
          options.merge!(:nonce => nonce)
        end
        @script_tag = ScriptTag.new(options)
      end

      def show_everywhere?
        IntercomRails.config.include_for_logged_out_users
      end

      def enabled_for_environment?
        enabled_environments = IntercomRails.config.enabled_environments
        return true if enabled_environments.nil?
        enabled_environments.map(&:to_s).include?(Rails.env)
      end

    end

  end

end
