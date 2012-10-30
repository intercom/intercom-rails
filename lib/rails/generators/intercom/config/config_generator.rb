module Intercom
  module Generators
    class ConfigGenerator < ::Rails::Generators::Base

      def self.source_root
        File.dirname(__FILE__)
      end

      argument :app_id, :desc => "Your Intercom app-id, which can be found here: https://www.intercom.io/apps/api_keys"

      def create_config_file
        @app_id = app_id
        template("intercom.rb.erb", "config/initializers/intercom.rb")
      end

    end
  end
end
