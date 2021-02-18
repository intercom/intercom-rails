require 'spec_helper'

require 'action_controller'

require 'rails'
require 'rspec/rails'

module Rails
  def self.env
    ActiveSupport::StringInquirer.new("production")
  end
end

module IntercomRails
  class Application < Rails::Application
    config.secret_key_base = 'secret_key_base'

    def routes
      TestRoutes
    end
  end
end

class ActionController::Base
  include IntercomRails::CustomDataHelper
  include IntercomRails::AutoInclude::Method
  if respond_to? :after_action
    after_action :intercom_rails_auto_include
  else
    after_filter :intercom_rails_auto_include
  end
end

require 'test_controller'

TestRoutes = ActionDispatch::Routing::RouteSet.new
TestRoutes.draw do
  TestController.public_instance_methods.each do |method|
    get "test/#{method}", to: "test##{method}"
  end
end

class ActionController::Base
  include TestRoutes.url_helpers
  include TestRoutes.mounted_helpers
end

RSpec.configure do |config|
  config.before(:each) do
    IntercomRails.config.app_id = "abc123"
  end
end