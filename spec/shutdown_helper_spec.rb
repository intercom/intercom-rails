require 'spec_helper'
require 'action_controller'

describe TestController, type: :controller do
  include IntercomRails::ShutdownHelper
  it 'clears response intercom-session-{app_id} cookie' do
    IntercomRails::ShutdownHelper.intercom_shutdown_helper(cookies)
    expect(cookies.has_key?('intercom-id-abc123')).to eq true
  end
  it 'creates session[:perform_intercom_shutdown] var' do
    IntercomRails::ShutdownHelper.prepare_intercom_shutdown(session)
    expect(session[:perform_intercom_shutdown]).to eq true
  end
  it 'erase intercom cookie, set preform_intercom_shutdown sessions to nil' do
    session[:perform_intercom_shutdown] = true
    IntercomRails::ShutdownHelper.intercom_shutdown(session, cookies)
    expect(session[:perform_intercom_shutdown]).to eq nil
    expect(cookies.has_key?('intercom-id-abc123')).to eq true
  end
end
