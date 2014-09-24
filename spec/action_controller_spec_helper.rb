require 'spec_helper'

require 'action_controller'

require "rails/all"
require 'rspec/rails'

module Rails
  def self.env
    ActiveSupport::StringInquirer.new("production")
  end
end

TestRoutes = ActionDispatch::Routing::RouteSet.new
TestRoutes.draw do
  get ':controller(/:action)'
end

module IntercomRails
  class Application < Rails::Application
    def routes
      TestRoutes
    end
  end
end

class ActionController::Base
  include IntercomRails::CustomDataHelper
  include IntercomRails::AutoInclude::Method
  after_filter :intercom_rails_auto_include

  include TestRoutes.url_helpers
  include TestRoutes.mounted_helpers
end

RSpec.configure do |config|
  config.before(:each) do
    IntercomRails.config.app_id = "abc123"
  end
end