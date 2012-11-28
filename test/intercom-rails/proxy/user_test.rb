require 'test_setup'

class UserTest < MiniTest::Unit::TestCase

  User = IntercomRails::Proxy::User

  include InterTest
  include IntercomRails

  DUMMY_USER = dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')

  def test_raises_error_when_no_user_found
    assert_raises(IntercomRails::NoUserFoundError) {
      User.current_in_context(Object.new)
    }
  end

  def test_finds_current_user
    object_with_current_user_method = Object.new
    object_with_current_user_method.instance_eval do
      def current_user
        DUMMY_USER
      end
    end

    @user_proxy = User.current_in_context(object_with_current_user_method)
    assert_user_found 
  end

  def test_finds_user_instance_variable
    object_with_instance_variable = Object.new
    object_with_instance_variable.instance_eval do
      @user = DUMMY_USER 
    end

    @user_proxy = User.current_in_context(object_with_instance_variable)
    assert_user_found 
  end

  def test_finds_config_user
    object_from_config = Object.new
    object_from_config.instance_eval do
      def something_esoteric
        DUMMY_USER
      end
    end

    IntercomRails.config.user.current = Proc.new { something_esoteric }
    @user_proxy = User.current_in_context(object_from_config)
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

    IntercomRails.config.user.custom_data = {
      'plan' => :plan
    }

    @user_proxy = User.new(plan_dummy_user)
    assert_equal 'pro', @user_proxy.to_hash['plan']
  end

  def test_valid_returns_true_if_user_id_or_email
    assert_equal true, User.new(DUMMY_USER).valid?
  end

  def test_includes_custom_data_from_intercom_custom_data
    object_with_intercom_custom_data = Object.new
    object_with_intercom_custom_data.instance_eval do
      def intercom_custom_data
        o = Object.new 
        o.instance_eval do 
          def user
            {:ponies => :rainbows}
          end
        end 

        o
      end
    end

    @user_proxy = User.new(DUMMY_USER, object_with_intercom_custom_data) 
    assert_equal :rainbows, @user_proxy.to_hash[:ponies]
  end

  def test_whiny_nil
    NilClass.class_eval do
      def id
        raise ArgumentError, "boo"
      end
    end

    search_object = nil 
    assert_equal false, User.new(search_object).valid?
  end

end
