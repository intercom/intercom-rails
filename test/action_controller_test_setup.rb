require 'test_setup'

require 'pry'
require 'action_controller'
require 'action_controller/test_case'

def dummy_user(options = {})
  user = Struct.new(:email, :name).new
  user.email = options[:email] || 'ben@intercom.io'
  user.name = options[:name] || 'Ben McRedmond'
  user
end

TestRoutes = ActionDispatch::Routing::RouteSet.new
TestRoutes.draw do
  get ':controller(/:action)'
end


class ActionController::Base

  include IntercomRails::ScriptTagHelperCallTracker
  after_filter IntercomRails::AutoIncludeFilter

  include TestRoutes.url_helpers
  include TestRoutes.mounted_helpers

end

class ActionController::TestCase

  def setup
    super
    @routes = TestRoutes
  end
  
end
