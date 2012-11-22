require 'active_support/core_ext/string/output_safety'
require 'test_setup'

class ScriptTagHelperTest < MiniTest::Unit::TestCase

  include IntercomRails::ScriptTagHelper

  def test_delegates_to_script_tag_generate
    delegated = false
    IntercomRails::ScriptTag.stub(:generate) {
      delegated = true
    }

    intercom_script_tag({})
    assert(delegated, "should delegate to ScriptTag#generate")
  ensure
    IntercomRails::ScriptTag.rspec_reset
  end

  def test_sets_instance_variable
    fake_action_view = fake_action_view_class.new
    obj = Object.new

    fake_action_view.instance_variable_set(:@controller, obj)

    fake_action_view.intercom_script_tag({})
    assert_equal obj.instance_variable_get(IntercomRails::SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE), true
  end

end
