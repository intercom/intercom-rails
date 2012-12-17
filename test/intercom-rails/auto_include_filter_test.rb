require 'action_controller_test_setup'

class TestController < ActionController::Base

  def without_user 
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_user_instance_variable
    @user = dummy_user
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_user_and_app_instance_variables
    @user = dummy_user
    @app = dummy_company
    render :text => params[:body], :content_type => 'text/html'
  end
  
  def with_user_instance_variable_and_custom_data
    @user = dummy_user
    intercom_custom_data.user['testing_stuff'] = true 
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

  include InterTest

  tests TestController

  def setup
    super
    IntercomRails.config.app_id = 'my_app_id'
  end

  def teardown
    IntercomRails.config.app_id = nil
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
    assert_includes @response.body, IntercomRails.config.app_id 
    assert_includes @response.body, "ben@intercom.io"
    assert_includes @response.body, "Ben McRedmond"
  end

  def test_user_instance_variable_present_with_body_tag_and_custom_data
    get :with_user_instance_variable_and_custom_data, :body => "<body>Hello world</body>"
    assert_includes @response.body, "<script>"
    assert_includes @response.body, "testing_stuff"
  end

  def test_current_user_method_present_with_body_tag
    get :with_current_user_method, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "ciaran@intercom.io"
    assert_includes @response.body, "Ciaran Lee"
  end

  def test_setting_current_user_with_intercom_config
    IntercomRails.config.user.current = Proc.new { @admin }
    get :with_admin_instance_variable, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "eoghan@intercom.io"
    assert_includes @response.body, "Eoghan McCabe"
  end

  def test_library_url_default
    get :with_current_user_method, :body => "<body>Hello world</body>"
    assert_includes @response.body, "<script>"
    assert_includes @response.body, "s.src = 'https://api.intercom.io/api/js/library.js"
  end

  def test_library_url_override
    IntercomRails.config.library_url = 'http://a.b.c.d/library.js'
    get :with_current_user_method, :body => "<body>Hello world</body>"
    assert_includes @response.body, "<script>"
    assert_includes @response.body, "s.src = 'http://a.b.c.d/library.js"
  end

  def test_auto_insert_with_api_secret_set
    IntercomRails.config.api_secret = 'abcd'
    get :with_current_user_method, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "user_hash"
    assert_includes @response.body, Digest::SHA1.hexdigest('abcd' + @controller.current_user.email)
  end

  def test_no_app_id_present
    IntercomRails.config.app_id = nil
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

  def test_includes_company
    IntercomRails.config.company.current = Proc.new { @app }
    get :with_user_and_app_instance_variables, :body => "<body>Hello world</body>"

    assert_includes @response.body, "<script>"
    assert_includes @response.body, "company"
    assert_includes @response.body, "6"
  end

end
