require 'spec_helper'
require 'action_controller'

describe TestController, type: :controller do
  include IntercomRails::ShutdownHelper
  it 'clears response intercom-session-{app_id} cookie' do
    IntercomRails::ShutdownHelper.intercom_shutdown_helper(self)
    expect(self.response.cookies).to eq({"intercom-session-abc123"=>nil})
  end
end
