module IntercomRails
  class Railtie < Rails::Railtie
    initializer "intercom_on_rails.script_tag_helper.rb" do |app|
      ActionView::Base.send :include, ScriptTagHelper
    end

    initializer "intercom_on_rails.auto_include_filter.rb" do |app|
      ActionController::Base.send :include, ScriptTagHelperCallTracker
      ActionController::Base.send :after_filter, AutoIncludeFilter 
    end
  end
end
