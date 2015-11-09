require 'active_support/time'
require 'spec_helper'

describe IntercomRails::ScriptTagHelper do
  include IntercomRails::ScriptTagHelper

  it 'delegates to script tag ' do
    expect(IntercomRails::ScriptTag).to receive(:generate)
    intercom_script_tag({})
  end

  it 'does not use dummy data if app_id is set in development' do
    allow(Rails).to receive(:development?).and_return true
    output = intercom_script_tag({app_id: 'thisismyappid', email:'foo'})
    expect(output).to include("/widget/thisismyappid")
  end

  it 'sets instance variable to record that it was called' do
    fake_action_view = fake_action_view_class.new
    obj = Object.new

    fake_action_view.instance_variable_set(:@controller, obj)

    fake_action_view.intercom_script_tag({})
    expect(obj.instance_variable_get(IntercomRails::SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE)).to eq(true)
  end
end
