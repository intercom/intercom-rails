module Intercom
  module Generators
    class ConfigGenerator < ::Rails::Generators::Base

      def self.source_root
        File.dirname(__FILE__)
      end

      argument :app_id, :desc => "Your Intercom app-id, which can be found here: https://app.intercom.io/apps/api_keys"
      argument :api_secret, :desc => "Your Intercom api-secret, used for secure mode", :optional => true
      argument :api_key, :desc => "An Intercom API key, for various rake tasks", :optional => true

      FALSEY_RESPONSES = ['n', 'no']
      def create_config_file
        @app_id = app_id
        @api_secret = api_secret
        @api_key = api_key
        @include_for_logged_out_users = false

        introduction = <<-desc
Intercom will automatically insert its javascript before the closing '</body>'
tag on every page where it can find a logged-in user. Intercom by default
looks for logged-in users, in the controller, via 'current_user' and '@user'.

Is the logged-in user accessible via either 'current_user' or '@user'? [Yn]
        desc

        print "#{introduction.strip} "
        default_ok = $stdin.gets.strip.downcase

        if FALSEY_RESPONSES.include?(default_ok)
          custom_current_user_question = <<-desc

How do you access the logged-in user in your controllers? This can be
any Ruby code, e.g. 'current_customer', '@admin', etc.:
          desc

          print "#{custom_current_user_question.rstrip} "
          @current_user = $stdin.gets.strip
        end

        template("intercom.rb.erb", "config/initializers/intercom.rb")
      end

    end
  end
end
