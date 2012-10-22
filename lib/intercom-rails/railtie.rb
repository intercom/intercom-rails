require 'intercom-rails/script_tag_helper'
require 'intercom-rails/action_controller_patch'

module IntercomRails
  class Railtie < Rails::Railtie
    initializer "intercom_on_rails.script_tag_helper.rb" do |app|
      ActionView::Base.send :include, ScriptTagHelper
    end

    initializer "intercom_on_rails.active_controller.rb" do |app|
      ActionController::Base.send :include, ActionControllerPatch
    end
  end
end