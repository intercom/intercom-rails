require 'action_controller_spec_helper'

class TestController < ActionController::Base
  skip_after_filter :intercom_rails_auto_include, :only => :with_user_instance_variable_after_filter_skipped

  def without_user
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_user_instance_variable
    @user = dummy_user
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_user_instance_variable_after_filter_skipped
    with_user_instance_variable
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

  def with_mongo_like_user
    @user = Struct.new(:id).new.tap do |user|
      user.id = DummyBSONId.new('deadbeaf1234mongo')
    end
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_numeric_user_id
    @user = Struct.new(:id).new.tap do |user|
      user.id = 123
    end
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_current_user_method
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_admin_instance_variable
    @admin = dummy_user(:email => 'eoghan@intercom.io', :name => 'Eoghan McCabe')
    render :text => params[:body], :content_type => 'text/html'
  end

  def with_some_tricky_string
    @user = dummy_user(:email => "\\\"foo\"")
    render :text => params[:body], :content_type => 'text/html'
  end

  def current_user
    raise NameError if params[:action] != 'with_current_user_method'
    dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')
  end
end

describe TestController, type: :controller do
  it 'has no intercom script if no user present' do
    get :without_user, :body => "<body>Hello world</body>"
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'has no intercom script if no body tag' do
    get :with_user_instance_variable, :body => "Hello world"
    expect(response.body).to eq("Hello world")
  end

  it 'has no intercom script if user present but unuseable' do
    get :with_unusable_user_instance_variable, :body => "<body>Hello world</body>"
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'includes intercom script if valid user present' do
    get :with_user_instance_variable, :body => "<body>Hello world</body>"
    expect(response.body).to include("<body>Hello world")
    expect(response.body).to include(IntercomRails.config.app_id)
    expect(response.body).to include("ben@intercom.io")
    expect(response.body).to include("Ben McRedmond")
    expect(response.body).to include("</script>\n</body>")
  end

  it 'includes custom data' do
    get :with_user_instance_variable_and_custom_data, :body => "<body>Hello world</body>"
    expect(response.body).to include("testing_stuff")
  end

  it 'finds user from current_user method' do
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).to include("<script>")
    expect(response.body).to include("ciaran@intercom.io")
    expect(response.body).to include("Ciaran Lee")
  end

  it 'finds user using config.user.current proc' do
    IntercomRails.config.user.current = Proc.new { @admin }
    get :with_admin_instance_variable, :body => "<body>Hello world</body>"
    expect(response.body).to include("<script>")
    expect(response.body).to include("eoghan@intercom.io")
    expect(response.body).to include("Eoghan McCabe")
  end

  it 'excludes users if necessary' do
    IntercomRails.config.user.exclude_if = Proc.new {|user| user.email.start_with?('ciaran')}
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).not_to include("<script>")
    expect(response.body).not_to include("ciaran@intercom.io")
    expect(response.body).not_to include("Ciaran Lee")
  end

  it 'uses default library_url' do
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).to include("<script>")
    expect(response.body).to include("s.src='https://widget.intercom.io/widget/abc123'")
  end

  it 'allows library_url override' do
    IntercomRails.config.library_url = 'http://a.b.c.d/library.js'
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).to include("<script>")
    expect(response.body).to include("s.src='http://a.b.c.d/library.js")
  end

  it 'to_s non numeric user_id to avoid nested structure for bson ids' do
    get :with_mongo_like_user, :body => "<body>Hello world</body>"
    expect(response.body).not_to include("oid")
    expect(response.body).to include('"user_id":"deadbeaf1234mongo"')
  end

  it 'leaves numeric user_id alone to avoid unintended consequences' do
    get :with_numeric_user_id, :body => "<body>Hello world</body>"
    expect(response.body).not_to include("oid")
    expect(response.body).to include('"user_id":123')
  end

  it 'defaults to have no user_hash' do
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).not_to include("user_hash")
  end

  it 'inserts user_hash when api_secret set' do
    IntercomRails.config.api_secret = 'abcd'
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).to include("user_hash")
  end

  it 'does not inject if app_id blank' do
    IntercomRails.config.reset!
    IntercomRails.config.app_id = ' '
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'does not inject if intercom_script_tag already called' do
    fake_action_view = fake_action_view_class.new
    fake_action_view.instance_variable_set(:@controller, @controller)
    fake_action_view.intercom_script_tag({})

    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'does not inject if blacklisted controller' do
    stub_const("IntercomRails::AutoInclude::Filter::BLACKLISTED_CONTROLLER_NAMES", ["TestController"])
    get :with_current_user_method, :body => "<body>Hello world</body>"
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'includes company' do
    IntercomRails.config.company.current = Proc.new { @app }
    get :with_user_and_app_instance_variables, :body => "<body>Hello world</body>"
    expect(response.body).to include("company")
    expect(response.body).to include("6")
  end

  it 'can be skipped with skip_filter' do
    get :with_user_instance_variable_after_filter_skipped, :body => "<body>Hello world</body>"
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'escapes strings with \\s' do
    get :with_some_tricky_string, :body => "<body>Normal</body>"
    expect(response.body).to include("\"email\":\"\\\\\\\"foo\\\"\"")
  end

  it 'can be disabled in non whitelisted environments' do
    IntercomRails.config.enabled_environments = ["special"]
    get :with_user_instance_variable, :body => "<body>Hello world</body>"
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'is enabled in production' do
    IntercomRails.config.enabled_environments = ["production"]
    get :with_user_instance_variable, :body => "<body>Hello world</body>"
    expect(response.body).to include("ben@intercom.io")
    expect(response.body).to include("Ben McRedmond")
    expect(response.body).to include(IntercomRails.config.app_id)
    expect(response.body).to include("</script>\n</body>")
  end
end
