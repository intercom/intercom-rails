module IntercomRails
  class Railtie < Rails::Railtie
    initializer "intercom-rails" do |app|
      ActiveSupport.on_load :action_view do
        include ScriptTagHelper
      end
      ActiveSupport.on_load :action_controller do
        include CustomDataHelper
        include AutoInclude::Method

        if respond_to? :after_action
          after_action :intercom_rails_auto_include
        else
          after_filter :intercom_rails_auto_include
        end
      end
    end
  end
end
