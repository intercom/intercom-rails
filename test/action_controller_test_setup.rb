require 'intercom-rails'

require 'minitest/autorun'
require 'action_controller'
require 'action_controller/test_case'

def dummy_user
  user = Struct.new(:email, :name).new
  user.email = 'ben@intercom.io'
  user.name = 'Ben McRedmond'
  user
end

TestRoutes = ActionDispatch::Routing::RouteSet.new
TestRoutes.draw do
  get ':controller(/:action)'
end


class ActionController::Base

  include TestRoutes.url_helpers
  include TestRoutes.mounted_helpers

end

class ActionController::TestCase

  def setup
    super
    @routes = TestRoutes
  end
  
end
