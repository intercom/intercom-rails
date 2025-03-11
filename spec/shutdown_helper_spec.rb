require 'spec_helper'
require 'action_controller'

describe TestController, type: :controller do
  include IntercomRails::ShutdownHelper
  it 'clears response intercom-session-{app_id} cookie' do
    IntercomRails::ShutdownHelper.intercom_shutdown_helper(cookies, 'intercom.com')
    expect(cookies.has_key?('intercom-session-abc123')).to eq true
  end
  it 'creates session[:perform_intercom_shutdown] var' do
    IntercomRails::ShutdownHelper.prepare_intercom_shutdown(session)
    expect(session[:perform_intercom_shutdown]).to eq true
  end
  it 'erase intercom cookie, set preform_intercom_shutdown sessions to nil' do
    session[:perform_intercom_shutdown] = true
    IntercomRails::ShutdownHelper.intercom_shutdown(session, cookies, 'intercom.com')
    expect(session[:perform_intercom_shutdown]).to eq nil
    expect(cookies.has_key?('intercom-session-abc123')).to eq true
  end
  it 'adds a leading dot to the domain if not present' do
    allow(cookies).to receive(:[]=)
    IntercomRails::ShutdownHelper.intercom_shutdown_helper(cookies, 'intercom.com')
    expect(cookies).to have_received(:[]=).with(
      "intercom-session-#{IntercomRails.config.app_id}",
      hash_including(domain: '.intercom.com')
    )
  end
  it 'keeps the domain as is if it already has a leading dot' do
    allow(cookies).to receive(:[]=)
    IntercomRails::ShutdownHelper.intercom_shutdown_helper(cookies, '.intercom.com')
    expect(cookies).to have_received(:[]=).with(
      "intercom-session-#{IntercomRails.config.app_id}",
      hash_including(domain: '.intercom.com')
    )
  end
  it 'handles localhost domain specially' do
    allow(cookies).to receive(:[]=)
    IntercomRails::ShutdownHelper.intercom_shutdown_helper(cookies, 'localhost')
    expect(cookies).to have_received(:[]=).with(
      "intercom-session-#{IntercomRails.config.app_id}",
      hash_not_including(domain: anything)
    )
  end
end
