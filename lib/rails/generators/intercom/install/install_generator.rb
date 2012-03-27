module Intercom
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Installs Intercom (https://www.intercom.io) into your Rails app"

      argument :app_id, :desc => "Your Intercom app-id, which can be found here: https://www.intercom.io/apps/api_keys"

      def update_layout
        snippet = <<-HTML
<!--
TODO add any user/app/situational data to the custom Hash below
e.g. :plan => 'Pro', :dashboard_page => 'http://dashboard.example.com/user-id'
See http://docs.intercom.io/#CustomData for more details about custom data
-->
<% if logged_in? %>
  <%= intercom_script_tag({
    :app_id => #{app_id.inspect},
    :user_id => current_user.id,
    :email => current_user.email,
    :name => current_user.name,
    :created_at => current_user.created_at,
    :custom_data => {

    }}) %>
<% end %>
</body>
HTML

        gsub_file('app/views/layouts/application.html.erb', %r{</body>}, snippet)
      end
    end
  end
end
