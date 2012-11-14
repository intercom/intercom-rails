module Intercom
  module Generators
    class ConfigGenerator < ::Rails::Generators::Base

      def self.source_root
        File.dirname(__FILE__)
      end

      argument :app_id, :desc => "Your Intercom app-id, which can be found here: https://www.intercom.io/apps/api_keys"
      argument :api_secret, :desc => "Your Intercom api-secret, used for secure mode"
      argument :api_key, :desc => "An Intercom API key, for various rake tasks"

      def create_config_file
        @app_id = app_id
        @api_secret = api_secret
        @api_key = api_key

        template("intercom.rb.erb", "config/initializers/intercom.rb")
      end

    end
  end
end
