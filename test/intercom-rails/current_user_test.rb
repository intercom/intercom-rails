require 'test_setup'

class CurrentUserTest < MiniTest::Unit::TestCase

  include IntercomRails

  DUMMY_USER = dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')

  def test_raises_error_when_no_user_found
    assert_raises(IntercomRails::CurrentUserNotFoundError) {
      CurrentUser.new(Object.new)
    }
  end

  def test_finds_current_user
    object_with_current_user_method = Object.new
    object_with_current_user_method.instance_eval do
      def current_user
        DUMMY_USER
      end
    end

    @current_user = CurrentUser.new(object_with_current_user_method)
    assert_user_found 
  end

  def test_finds_user_instance_variable
    object_with_instance_variable = Object.new
    object_with_instance_variable.instance_eval do
      @user = DUMMY_USER 
    end

    @current_user = CurrentUser.new(object_with_instance_variable)
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
    @current_user = CurrentUser.new(object_from_config)
    assert_user_found 
  end

  def assert_user_found
    assert_equal DUMMY_USER, @current_user.user
  end

end
