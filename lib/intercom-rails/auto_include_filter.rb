# frozen_string_literal: true

module IntercomRails

  module AutoInclude
    module Method
      def intercom_rails_auto_include
        IntercomRails::AutoInclude::Filter.filter(self)
      end
    end

    class Filter
      CLOSING_BODY_TAG = "</body>"
      BLOCKED_CONTROLLER_NAMES = %w{ Devise::PasswordsController }

      def self.filter(controller)
        return if BLOCKED_CONTROLLER_NAMES.include?(controller.class.name)

        auto_include_filter = new(controller)

        if auto_include_filter.include_javascript?
          auto_include_filter.include_javascript!
        else
          auto_include_filter.exclude_javascript
        end

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
        response.body = response.body.insert(response.body.rindex(CLOSING_BODY_TAG), intercom_script_tag.to_s)
      end

      def include_javascript?
        enabled_for_environment? &&
        !intercom_script_tag_called_manually? &&
        html_content_type? &&
        response_has_closing_body_tag? &&
        intercom_script_tag.valid?
      end

      def exclude_javascript
        callback = exclude_javascript_callback
        controller.send(callback) if controller.respond_to?(callback)
      end

      def csp_sha256
        intercom_script_tag.csp_sha256
      end

      private
      def response
        controller.response
      end

      def html_content_type?
        if response.respond_to?(:media_type)
          response.media_type == 'text/html'
        else
          response.content_type == 'text/html'
        end
      end

      def response_has_closing_body_tag?
        response.body.include? CLOSING_BODY_TAG
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
        @script_tag ||= ScriptTag.new(options)
      end

      def show_everywhere?
        IntercomRails.config.include_for_logged_out_users
      end

      def exclude_javascript_callback
        IntercomRails.config.exclude_javascript_callback ||
          :intercom_javascript_excluded
      end

      def enabled_for_environment?
        enabled_environments = IntercomRails.config.enabled_environments
        return true if enabled_environments.nil?
        enabled_environments.map(&:to_s).include?(Rails.env)
      end

    end

  end

end
