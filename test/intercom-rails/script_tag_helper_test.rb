require "active_support/core_ext/string/output_safety"
require 'intercom-rails/script_tag_helper'
require 'minitest/autorun'

class IntercomRailsTest < MiniTest::Unit::TestCase
  include IntercomRails::ScriptTagHelper
  def test_output_is_html_safe?
    assert_equal true, intercom_script_tag({}).html_safe?
  end

  def test_converts_times_to_unix_timestamps
    now = Time.now
    assert_match(/.created_at.\s*:\s*#{now.to_i}/, intercom_script_tag({:created_at => now}))
    assert_match(/.something.\s*:\s*#{now.to_i}/, intercom_script_tag({:custom_data => {"something" => now}}))
  end
end