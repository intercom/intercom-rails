require 'action_controller_spec_helper'

class TestController < ActionController::Base
  if respond_to? :skip_after_action
    skip_after_action :intercom_rails_auto_include, :only => :with_current_user_method_after_filter_skipped
  else
    skip_after_filter :intercom_rails_auto_include, :only => :with_current_user_method_after_filter_skipped
  end

  def without_user
    @current_user = nil
    render_content("<body>Hello world</body>")
  end

  def without_current_user_method_but_with_user_instance_variable
    @user = dummy_user
    render_content("<body>Hello world</body>")
  end

  def with_current_user_method
    @current_user = dummy_user
    render_content("<body>Hello world</body>")
  end

  def with_current_user_method_no_body_tag
    @current_user = dummy_user
    render_content("Hello world")
  end

  def with_current_user_method_after_filter_skipped
    with_current_user_method
  end

  def with_user_and_app_instance_variables
    @user = dummy_user
    @app = dummy_company
    render_content("<body>Hello world</body>")
  end

  def with_current_user_method_and_custom_data
    @current_user = dummy_user
    intercom_custom_data.user['testing_stuff'] = true
    render_content("<body>Hello world</body>")
  end

  def with_unusable_current_user
    @current_user = Object.new
    render_content("<body>Hello world</body>")
  end

  def with_mongo_like_user
    @current_user = Struct.new(:id).new.tap do |user|
      user.id = DummyBSONId.new('deadbeaf1234mongo')
    end
    render_content("<body>Hello world</body>")
  end

  def with_numeric_user_id
    @current_user = Struct.new(:id).new.tap do |user|
      user.id = 123
    end
    render_content("<body>Hello world</body>")
  end

  def with_admin_instance_variable
    @admin = dummy_user(:email => 'eoghan@intercom.io', :name => 'Eoghan McCabe')
    render_content("<body>Hello world</body>")
  end

  def with_some_tricky_string
    @current_user = dummy_user(:email => "\\\"foo\"")
    render_content("<body>Hello world</body>")
  end

  private

  def render_content(body)
    if Rails::VERSION::MAJOR >= 5
      render :body => body, :content_type => 'text/html'
    else
      render :text => body, :content_type => 'text/html'
    end
  end

  def current_user
    @current_user
  end
end

describe TestController, type: :controller do
  it 'has no intercom script if no user present' do
    get :without_user
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'has no intercom script if no user present even if @user is set' do
    get :without_current_user_method_but_with_user_instance_variable
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it "falls back to instance variable if configured to" do
    IntercomRails.config.user.current = [
      Proc.new { current_user },
      Proc.new { @user }
    ]
    get :without_current_user_method_but_with_user_instance_variable
    expect(response.body).to include('<script id="IntercomSettingsScriptTag">')
    expect(response.body).to include("ben@intercom.io")
    expect(response.body).to include("Ben McRedmond")
  end

  it 'has no intercom script if no body tag' do
    get :with_current_user_method_no_body_tag
    expect(response.body).to eq("Hello world")
  end

  it 'has no intercom script if user present but unuseable' do
    get :with_unusable_current_user
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'includes intercom script if valid user present' do
    get :with_current_user_method
    expect(response.body).to include("<body>Hello world")
    expect(response.body).to include(IntercomRails.config.app_id)
    expect(response.body).to include("ben@intercom.io")
    expect(response.body).to include("Ben McRedmond")
    expect(response.body).to include("</script>\n</body>")
  end

  it 'includes custom data' do
    get :with_current_user_method_and_custom_data
    expect(response.body).to include("testing_stuff")
  end

  it 'finds user from current_user method' do
    get :with_current_user_method
    expect(response.body).to include('<script id="IntercomSettingsScriptTag">')
    expect(response.body).to include("ben@intercom.io")
    expect(response.body).to include("Ben McRedmond")
  end

  it 'finds user using config.user.current proc' do
    IntercomRails.config.user.current = Proc.new { @admin }
    get :with_admin_instance_variable
    expect(response.body).to include('<script id="IntercomSettingsScriptTag">')
    expect(response.body).to include("eoghan@intercom.io")
    expect(response.body).to include("Eoghan McCabe")
  end

  it 'finds user using config.user.current proc array' do
    IntercomRails.config.user.current = [Proc.new { @admin }, Proc.new { @user_object }]
    get :with_admin_instance_variable
    expect(response.body).to include('<script id="IntercomSettingsScriptTag">')
    expect(response.body).to include("eoghan@intercom.io")
    expect(response.body).to include("Eoghan McCabe")
  end

  it 'excludes users if necessary' do
    IntercomRails.config.include_for_logged_out_users = true
    IntercomRails.config.user.exclude_if = Proc.new {|user| user.email.start_with?('ben')}
    get :with_current_user_method
    expect(response.body).not_to include('<script id="IntercomSettingsScriptTag">')
    expect(response.body).not_to include("ben@intercom.io")
    expect(response.body).not_to include("Ben McRedmond")
  end

  it 'uses default library_url' do
    get :with_current_user_method
    expect(response.body).to include('<script id="IntercomSettingsScriptTag">')
    expect(response.body).to include("s.src='https://widget.intercom.io/widget/abc123'")
  end

  it 'allows library_url override' do
    IntercomRails.config.library_url = 'http://a.b.c.d/library.js'
    get :with_current_user_method
    expect(response.body).to include('<script id="IntercomSettingsScriptTag">')
    expect(response.body).to include("s.src='http://a.b.c.d/library.js")
  end

  it 'to_s non numeric user_id to avoid nested structure for bson ids' do
    get :with_mongo_like_user
    expect(response.body).not_to include("oid")
    expect(response.body).to include('"user_id":"deadbeaf1234mongo"')
  end

  it 'leaves numeric user_id alone to avoid unintended consequences' do
    get :with_numeric_user_id
    expect(response.body).not_to include("oid")
    expect(response.body).to include('"user_id":123')
  end

  it 'defaults to have no user_hash' do
    get :with_current_user_method
    expect(response.body).not_to include("user_hash")
  end

  it 'inserts user_hash when api_secret set' do
    IntercomRails.config.api_secret = 'abcd'
    get :with_current_user_method
    expect(response.body).to include("user_hash")
  end

  it 'does not inject if app_id blank' do
    IntercomRails.config.reset!
    IntercomRails.config.app_id = ' '
    get :with_current_user_method
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'does not inject if intercom_script_tag already called' do
    fake_action_view = fake_action_view_class.new
    fake_action_view.instance_variable_set(:@controller, @controller)
    fake_action_view.intercom_script_tag({})

    get :with_current_user_method
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'does not inject if blacklisted controller' do
    stub_const("IntercomRails::AutoInclude::Filter::BLACKLISTED_CONTROLLER_NAMES", ["TestController"])
    get :with_current_user_method
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'includes company' do
    IntercomRails.config.user.current = Proc.new { @user }
    IntercomRails.config.company.current = Proc.new { @app }
    get :with_user_and_app_instance_variables
    expect(response.body).to include("company")
    expect(response.body).to include("6")
  end

  it 'excludes company if necessary' do
    IntercomRails.config.company.current = Proc.new { @app }
    IntercomRails.config.company.exclude_if = Proc.new {|app| app.name == 'Intercom' }
    get :with_user_and_app_instance_variables
    expect(response.body).not_to include("company")
    expect(response.body).not_to include("6")
  end

  it 'can be skipped with skip_filter' do
    get :with_current_user_method_after_filter_skipped
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'escapes strings with \\s' do
    get :with_some_tricky_string
    expect(response.body).to include("\"email\":\"\\\\\\\"foo\\\"\"")
  end

  it 'can be disabled in non whitelisted environments' do
    IntercomRails.config.enabled_environments = ["special"]
    get :with_current_user_method
    expect(response.body).to eq("<body>Hello world</body>")
  end

  it 'is enabled in production' do
    IntercomRails.config.enabled_environments = ["production"]
    get :with_current_user_method
    expect(response.body).to include("ben@intercom.io")
    expect(response.body).to include("Ben McRedmond")
    expect(response.body).to include(IntercomRails.config.app_id)
    expect(response.body).to include("</script>\n</body>")
  end

  context 'content security policy support' do
    before do
      require 'auto_include_filter_spec_csp_helper'
    end
    it 'injects nonce if csp_nonce_hook is defined' do
      IntercomRails.config.api_secret = 'abcd'
      get :with_current_user_method
      expect(response.body).to include('nonce="aaaa"')
    end
  end
end
