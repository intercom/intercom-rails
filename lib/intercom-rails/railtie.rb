module IntercomRails
  class Railtie < Rails::Railtie
    initializer "intercom-rails" do |app|
      ActionView::Base.send :include, ScriptTagHelper
      ActionController::Base.send :include, CustomDataHelper
      ActionController::Base.send :include, AutoInclude::Method
      if ActionController::Base.respond_to? :after_action
        ActionController::Base.after_action :intercom_rails_auto_include
      else
        ActionController::Base.after_filter :intercom_rails_auto_include
      end
    end
  end
end
