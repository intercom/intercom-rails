require 'action_controller_test_setup'

class TestController < ActionController::Base

  def without_user 
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_user_instance_variable
    @user = dummy_user
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_unusable_user_instance_variable
    @user = Object.new
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_current_user_method
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_admin_instance_variable
    @admin = dummy_user(:email => 'eoghan@intercom.io', :name => 'Eoghan McCabe')
    render :text => params[:body], :content_type => 'text/html'
  end

  def current_user
    raise NameError if params[:action] != 'with_current_user_method'
    dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')
  end

end

class AutoIncludeFilterTest < ActionController::TestCase 

  tests TestController

  def setup
    super
    ENV['INTERCOM_APP_ID'] = 'my_app_id'
  end
  
  def test_no_user_present
    get :without_user, :body => "<body>Hello world</body>"
    assert_equal @response.body, "<body>Hello world</body>"
  end

  def test_user_present_with_no_body_tag
    get :with_user_instance_variable, :body => "Hello world"
    assert_equal @response.body, "Hello world"
  end

  def test_user_present_but_unusuable
    get :with_unusable_user_instance_variable, :body => "Hello world"
    assert_equal @response.body, "Hello world"
  end

  def test_user_instance_variable_present_with_body_tag
    get :with_user_instance_variable, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, ENV['INTERCOM_APP_ID']
    assert_includes @response.body, "ben@intercom.io"
    assert_includes @response.body, "Ben McRedmond"
  end

  def test_current_user_method_present_with_body_tag
    get :with_current_user_method, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "ciaran@intercom.io"
    assert_includes @response.body, "Ciaran Lee"
  end

  def test_setting_current_user_with_intercom_config
    IntercomRails.config.current_user = Proc.new { @admin }

    get :with_admin_instance_variable, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "eoghan@intercom.io"
    assert_includes @response.body, "Eoghan McCabe"
  end

  def test_no_app_id_present
    ENV.delete('INTERCOM_APP_ID')
    get :with_current_user_method, :body => "<body>Hello world</body>"

    assert_equal @response.body, "<body>Hello world</body>"
  end

  def test_manual_script_tag_helper_call
    fake_action_view = fake_action_view_class.new
    fake_action_view.instance_variable_set(:@controller, @controller)
    fake_action_view.intercom_script_tag({})

    get :with_current_user_method, :body => "<body>Hello world</body>"
    assert_equal @response.body,  "<body>Hello world</body>"
  end

end
