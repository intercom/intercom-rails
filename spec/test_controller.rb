class TestController < ActionController::Base
  if respond_to? :skip_after_action
    skip_after_action :intercom_rails_auto_include, :only => :with_user_instance_variable_after_filter_skipped
  else
    skip_after_filter :intercom_rails_auto_include, :only => :with_user_instance_variable_after_filter_skipped
  end

  def without_user
    render_content("<body>Hello world</body>")
  end

  def with_user_instance_variable
    @user = dummy_user
    render_content("<body>Hello world</body>")
  end

  def with_user_instance_variable_no_body_tag
    render_content("Hello world")
  end

  def with_user_instance_variable_after_filter_skipped
    with_user_instance_variable
  end

  def with_user_and_app_instance_variables
    @user = dummy_user
    @app = dummy_company
    render_content("<body>Hello world</body>")
  end

  def with_user_instance_variable_and_custom_data
    @user = dummy_user
    intercom_custom_data.user['testing_stuff'] = true
    render_content("<body>Hello world</body>")
  end

  def with_unusable_user_instance_variable
    @user = Object.new
    render_content("<body>Hello world</body>")
  end

  def with_mongo_like_user
    @user = Struct.new(:id).new.tap do |user|
      user.id = DummyBSONId.new('deadbeaf1234mongo')
    end
    render_content("<body>Hello world</body>")
  end

  def with_numeric_user_id
    @user = Struct.new(:id).new.tap do |user|
      user.id = 123
    end
    render_content("<body>Hello world</body>")
  end

  def with_current_user_method
    render_content("<body>Hello world</body>")
  end

  def with_admin_instance_variable
    @admin = dummy_user(:email => 'eoghan@intercom.io', :name => 'Eoghan McCabe')
    render_content("<body>Hello world</body>")
  end

  def with_some_tricky_string
    @user = dummy_user(:email => "\\\"foo\"")
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
    raise NameError if params[:action] != 'with_current_user_method'
    dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')
  end
end
