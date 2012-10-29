require 'action_controller_test_setup'

class TestController < ActionController::Base

  #include IntercomRails::ActionControllerPatch

  #def not_logged_in 
  #end

  def logged_in
    @user = dummy_user
    render :text => "Hello world", :content_type => 'text/html'
  end

end


class ActionControllerPatchTest < ActionController::TestCase 

  tests TestController

  def test_user_present_response
    get :logged_in 
    assert_equal "Hello world", @response.body
  end

end
