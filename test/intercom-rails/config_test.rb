require 'test_setup'

class ConfigTest < MiniTest::Unit::TestCase 

  def test_setting_app_id
    IntercomRails.config.app_id = "1234"
    assert_equal IntercomRails.config.app_id, "1234"
  end

  def test_setting_current_user
    current_user = Proc.new { @blah }
    IntercomRails.config.current_user = current_user
    assert_equal IntercomRails.config.current_user, current_user
  end

  def test_setting_current_user_not_to_a_proc
    assert_raises ArgumentError do
      IntercomRails.config.current_user = 1
    end
  end

  def test_configuring_intercom_with_block
    IntercomRails.config do |config|
      config.app_id = "4567"
    end

    assert_equal IntercomRails.config.app_id, "4567"
  end

end
