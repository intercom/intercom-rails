module RailsFootnotes
  module Generators
    class IntercomGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      desc "Installs Intercom.io into your Rails app"

      def update_layout
        snippet = HTML.gsub(/^\s{8}/, '')
        <% if logged_in? %>
          <%= intercom_script_tag({
            :app_id => 'your-app-id'
            :user_id => current_user.id
            :email => current_user.email
            :name => current_user.name
            :created_at => current_user.created_at
            :custom_data => {:plan => "Pro"}}) %>
        <% end %>
        </body>
        HTML
        
        gsub_file 'app/views/layouts/application.html.erb', %r{</body>}, snippet
      end
    end
  end
end
