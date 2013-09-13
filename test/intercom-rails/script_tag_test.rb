require 'active_support/core_ext/string/output_safety'
require 'active_support/time'
require 'test_setup'

class ScriptTagTest < MiniTest::Unit::TestCase

  include InterTest
  include IntercomRails

  def setup
    super
    IntercomRails.config.app_id = 'script_tag_test'
  end

  def test_output_is_html_safe?
    assert_equal true, ScriptTag.generate({}).html_safe?
  end

  def test_converts_times_to_unix_timestamps
    time = Time.new(1993,02,13)
    top_level_time = ScriptTag.new(:user_details => {:created_at => time})
    assert_equal time.to_i, top_level_time.intercom_settings[:created_at]

    now = Time.now
    nested_time = ScriptTag.new(:user_details => {:custom_data => {"something" => now}})
    assert_equal now.to_i, nested_time.intercom_settings[:custom_data]["something"]

    utc_time = Time.utc(2013,04,03)
    time_zone = ActiveSupport::TimeZone.new('London')
    time_with_zone = ActiveSupport::TimeWithZone.new(utc_time, time_zone)
    time_from_time_with_zone = ScriptTag.new(:user_details => {:created_at => time_with_zone})
    assert_equal utc_time.to_i, time_from_time_with_zone.intercom_settings[:created_at]
  end

  def test_strips_out_nil_entries_for_standard_attributes
    %w(name email user_id).each do |standard_attribute|
      with_value = ScriptTag.new(:user_details => {standard_attribute => 'value'})
      assert_equal with_value.intercom_settings[standard_attribute], 'value'

      with_nil_value = ScriptTag.new(:user_details => {standard_attribute.to_sym => 'value'})
      assert with_nil_value.intercom_settings.has_key?(standard_attribute.to_sym), "should strip :#{standard_attribute} when nil"

      with_nil_value = ScriptTag.new(:user_details => {standard_attribute => 'value'})
      assert with_nil_value.intercom_settings.has_key?(standard_attribute), "should strip #{standard_attribute} when nil"
    end
  end

  def test_secure_mode_with_email
    script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io'}, :secret => 'abcdefgh')
    assert_equal OpenSSL::HMAC.hexdigest("sha256", 'abcdefgh', 'ciaran@intercom.io'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_with_user_id
    script_tag = ScriptTag.new(:user_details => {:user_id => '1234'}, :secret => 'abcdefgh')
    assert_equal OpenSSL::HMAC.hexdigest("sha256", 'abcdefgh', '1234'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_with_email_and_user_id
    script_tag = ScriptTag.new(:user_details => {:user_id => '1234', :email => 'ciaran@intercom.io'}, :secret => 'abcdefgh')
    assert_equal OpenSSL::HMAC.hexdigest("sha256", 'abcdefgh', '1234'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_with_secret_from_config
    IntercomRails.config.api_secret = 'abcd'
    script_tag = ScriptTag.new(:user_details => {:email => 'ben@intercom.io'})
    assert_equal OpenSSL::HMAC.hexdigest("sha256", 'abcd', 'ben@intercom.io'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_chooses_passed_secret_over_config
    IntercomRails.config.api_secret = 'abcd'
    script_tag = ScriptTag.new(:user_details => {:email => 'ben@intercom.io'}, :secret => '1234')
    assert_equal OpenSSL::HMAC.hexdigest("sha256", '1234', 'ben@intercom.io'), script_tag.intercom_settings[:user_hash]
    script_tag = ScriptTag.new(:user_details => {:user_id => 5678}, :secret => '1234')
    assert_equal OpenSSL::HMAC.hexdigest("sha256", '1234', '5678'), script_tag.intercom_settings[:user_hash]
  end

  def test_inbox_default_style
    IntercomRails.config.inbox.style = :default
    script_tag = ScriptTag.new
    expected_widget_settings= {'activator' => '#IntercomDefaultWidget'}
    assert_equal expected_widget_settings, script_tag.intercom_settings['widget']
  end

  def test_inbox_custom_style
    IntercomRails.config.inbox.style = :custom
    script_tag = ScriptTag.new
    expected_widget_settings = {'activator' => '#Intercom'}
    assert_equal expected_widget_settings, script_tag.intercom_settings['widget']
  end

  def test_company_discovery_and_inclusion
    IntercomRails.config.company.current = Proc.new { @app }
    object_with_app_instance_variable = Object.new
    object_with_app_instance_variable.instance_eval do
      @app = dummy_company 
    end

    script_tag = ScriptTag.new(:controller => object_with_app_instance_variable,
                               :find_current_company_details => true)
    expected_company = {'id' => '6', 'name' => 'Intercom'}
    assert_equal expected_company, script_tag.intercom_settings[:company]
  end

  def test_escapes_html_attributes
    nasty_email = "</script><script>alert('sup?');</script>"
    script_tag = ScriptTag.new(:user_details => {:email => nasty_email})
    assert !script_tag.output.include?(nasty_email), "script tag included"
  end

end
