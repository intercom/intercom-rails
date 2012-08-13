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

  def test_strips_out_nil_entries_for_standard_attributes
    %w(name email user_id).each do |standard_attribute|
      assert_match(/.#{standard_attribute}.\s*:\s*"value"/, intercom_script_tag({standard_attribute => 'value'}))
      assert(!intercom_script_tag({standard_attribute.to_sym => nil}).include?("\"#{standard_attribute}\":"), "should strip #{standard_attribute} when nil")
      assert(!intercom_script_tag({standard_attribute => nil}).include?("\"#{standard_attribute}\":"), "should strip #{standard_attribute} when nil")
    end
  end

  def test_secure_mode
    assert_match(/.user_hash.\s*:\s*"#{Digest::SHA1.hexdigest('abcdefgh' + 'ciaran@intercom.io')}"/, intercom_script_tag({:email => "ciaran@intercom.io"}, {:secret => 'abcdefgh'}))
    assert_match(/.user_hash.\s*:\s*"#{Digest::SHA1.hexdigest('abcdefgh' + '1234')}"/, intercom_script_tag({:id => 1234}, {:secret => 'abcdefgh'}))
  end
end
