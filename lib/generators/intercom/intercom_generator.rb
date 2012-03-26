module Intercom
  module Generators
    class IntercomGenerator < Rails::Generators::Base
      desc "Installs Intercom.io into your Rails app"

      argument :app_id, :desc => "The Intercom.io app-id token"

      def update_layout
        snippet = <<-HTML
<!-- TODO add any user/app/situational data to the Hash below -->
<% if logged_in? %>
  <%= intercom_script_tag({
    :app_id => #{app_id.inspect},
    :user_id => current_user.id,
    :email => current_user.email,
    :name => current_user.name,
    :created_at => current_user.created_at,
    :custom_data => {:plan => "Pro"}}) %>
<% end %>
</body>
HTML

        gsub_file('app/views/layouts/application.html.erb', %r{</body>}, snippet)
      end
    end
  end
end
