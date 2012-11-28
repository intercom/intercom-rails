require 'test_setup'

class UserProxyTest < MiniTest::Unit::TestCase

  include InterTest
  include IntercomRails

  DUMMY_USER = dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')

  def test_raises_error_when_no_user_found
    assert_raises(IntercomRails::NoUserFoundError) {
      UserProxy.from_current_user_in_object(Object.new)
    }
  end

  def test_finds_current_user
    object_with_current_user_method = Object.new
    object_with_current_user_method.instance_eval do
      def current_user
        DUMMY_USER
      end
    end

    @user_proxy = UserProxy.from_current_user_in_object(object_with_current_user_method)
    assert_user_found 
  end

  def test_finds_user_instance_variable
    object_with_instance_variable = Object.new
    object_with_instance_variable.instance_eval do
      @user = DUMMY_USER 
    end

    @user_proxy = UserProxy.from_current_user_in_object(object_with_instance_variable)
    assert_user_found 
  end

  def test_finds_config_user
    object_from_config = Object.new
    object_from_config.instance_eval do
      def something_esoteric
        DUMMY_USER
      end
    end

    IntercomRails.config.current_user = Proc.new { something_esoteric }
    @user_proxy = UserProxy.from_current_user_in_object(object_from_config)
    assert_user_found 
  end

  def assert_user_found
    assert_equal DUMMY_USER, @user_proxy.user
  end

  def test_includes_custom_data
    plan_dummy_user = DUMMY_USER.dup
    plan_dummy_user.instance_eval do
      def plan
        'pro'
      end
    end

    IntercomRails.config.custom_data = {
      'plan' => :plan
    }

    @user_proxy = UserProxy.new(plan_dummy_user)
    expected_custom_data = {'plan' => 'pro'}
    assert_equal expected_custom_data, @user_proxy.to_hash[:custom_data]
  end

  def test_valid_returns_true_if_user_id_or_email
    assert_equal true, UserProxy.new(DUMMY_USER).valid?
  end

  def test_includes_custom_data_from_intercom_custom_data
    object_with_intercom_custom_data = Object.new
    object_with_intercom_custom_data.instance_eval do
      def intercom_custom_data
        {:ponies => :rainbows}
      end
    end

    @user_proxy = UserProxy.new(DUMMY_USER, object_with_intercom_custom_data) 
    expected_custom_data = {:ponies => :rainbows}
    assert_equal expected_custom_data, @user_proxy.to_hash[:custom_data]
  end

  def test_valid_returns_false_for_nil
    search_object = false 
    search_object.stub(:id) { raise NameError }
    assert_equal false, UserProxy.new(search_object).valid?
  end

end
