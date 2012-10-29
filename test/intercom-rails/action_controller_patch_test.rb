require 'action_controller_test_setup'

class TestController < ActionController::Base

  def without_user 
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_user_instance_variable
    @user = dummy_user
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_current_user_method
    render :text => params[:body], :content_type => 'text/html'
  end

  def current_user
    raise NameError if params[:action] != 'with_current_user_method'
    dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')
  end

end

class ActionControllerPatchTest < ActionController::TestCase 

  tests TestController

  def setup
    super
    ENV['INTERCOM_APP_ID'] = 'abcd1234'
  end
  
  def test_no_user_present
    get :without_user, :body => "<body>Hello world</body>"
    assert_equal @response.body, "<body>Hello world</body>"
  end

  def test_user_present_with_no_body_tag
    get :with_user_instance_variable, :body => "Hello world"

    assert_equal @response.body, "Hello world"
  end

  def test_user_instance_variable_present_with_body_tag
    get :with_user_instance_variable, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "abcd1234"
    assert_includes @response.body, "ben@intercom.io"
    assert_includes @response.body, "Ben McRedmond"
  end

  def test_current_user_method_present_with_body_tag
    get :with_current_user_method, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "ciaran@intercom.io"
    assert_includes @response.body, "Ciaran Lee"
  end

  def test_no_app_id_present
    ENV.delete('INTERCOM_APP_ID')
    get :with_current_user_method, :body => "<body>Hello world</body>"

    assert_equal @response.body, "<body>Hello world</body>"
  end

end
