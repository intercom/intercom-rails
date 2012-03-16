require 'intercom-rails/script_tag_helper'

module IntercomRails
  class Railtie < Rails::Railtie
    initializer "intercom_on_rails.script_tag_helper.rb" do |app|
      ActionView::Base.send :include, ScriptTagHelper
    end
  end
end