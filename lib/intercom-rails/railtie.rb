module IntercomRails
  class Railtie < Rails::Railtie
    initializer "intercom-rails" do |app|
      ActionView::Base.send :include, ScriptTagHelper
      ActionController::Base.send :include, CustomDataHelper
      ActionController::Base.send :include, AutoInclude::Method
      ActionController::Base.after_filter :intercom_rails_auto_include
    end

    rake_tasks do
      load 'intercom-rails/intercom.rake'
    end
  end
end
