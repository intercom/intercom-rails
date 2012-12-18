require 'test_setup'

class ConfigTest < MiniTest::Unit::TestCase 

  include InterTest

  def test_setting_app_id
    IntercomRails.config.app_id = "1234"
    assert_equal IntercomRails.config.app_id, "1234"
  end

  def test_setting_current_user
    current_user = Proc.new { @blah }
    IntercomRails.config.user.current = current_user
    assert_equal IntercomRails.config.user.current, current_user
  end

  def test_setting_current_user_not_to_a_proc
    assert_raises ArgumentError do
      IntercomRails.config.user.current = 1
    end
  end

  def test_configuring_intercom_with_block
    IntercomRails.config do |config|
      config.app_id = "4567"
    end

    assert_equal IntercomRails.config.app_id, "4567"
  end

  def test_custom_data_rejects_non_proc_or_symbol_attributes
    exception = assert_raises ArgumentError do 
      IntercomRails.config.user.custom_data = {
        'foo' => Proc.new {},
        'bar' => 'heyheyhey!'
      }
    end 

    assert_equal "all custom_data attributes should be either a Proc or a symbol", exception.message
  end

  def test_setting_custom_data
    custom_data_config = {
      'foo' => Proc.new {},
      'bar' => :method_name
    }

    IntercomRails.config.user.custom_data = custom_data_config
    assert_equal custom_data_config, IntercomRails.config.user.custom_data
  end

  def test_setting_company_custom_data
    custom_data_config = {
      'the_local' => Proc.new { 'club 93' }
    }

    IntercomRails.config.company.custom_data = custom_data_config
    assert_equal custom_data_config, IntercomRails.config.company.custom_data
  end

  def test_setting_company_user_association
  end

  def test_setting_inbox_style
    IntercomRails.config.inbox.style = :custom
    assert_equal :custom, IntercomRails.config.inbox.style
  end

  def test_reset_clears_existing_config
    IntercomRails.config.user.custom_data = {'muffin' => :muffin}
    IntercomRails.config.reset!
    assert_equal nil, IntercomRails.config.user.custom_data
  end

  def test_reset_clears_inbox_config_too
    IntercomRails.config.inbox.style = :custom
    IntercomRails.config.reset!
    assert_equal nil, IntercomRails.config.inbox.style
  end

end
