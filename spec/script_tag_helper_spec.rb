require 'active_support/time'
require 'spec_helper'

describe IntercomRails::ScriptTagHelper do
  include IntercomRails::ScriptTagHelper

  it 'delegates to script tag ' do
    expect(IntercomRails::ScriptTag).to receive(:new)
    intercom_script_tag({})
  end

  it 'does not use dummy data if app_id is set in development' do
    allow(Rails).to receive(:development?).and_return true
    output = intercom_script_tag({app_id: 'thisismyappid', email:'foo'}).to_s
    expect(output).to include("/widget/thisismyappid")
  end

  it 'sets instance variable to record that it was called' do
    fake_action_view = fake_action_view_class.new
    obj = Object.new

    fake_action_view.instance_variable_set(:@controller, obj)

    fake_action_view.intercom_script_tag({})
    expect(obj.instance_variable_get(IntercomRails::SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE)).to eq(true)
  end

  context 'content security policy support' do
    it 'returns a valid sha256 hash for the CSP header' do
      #
      # See also spec/script_tag_spec.rb
      #
      script_tag = intercom_script_tag({
        :app_id => 'csp_sha_test',
        :email => 'marco@intercom.io',
        :user_id => 'marco',
      })
      expect(script_tag.csp_sha256).to eq("'sha256-/0mStQPBID1jSuXAoW0YtDqu8JmWUJJ5SdBB2u7Fy90='")
    end

    it 'inserts a valid nonce if present' do
      script_tag = intercom_script_tag({
        :app_id => 'csp_sha_test',
        :email => 'marco@intercom.io',
        :user_id => 'marco',
      }, {
        :nonce => 'pJwtLVnwiMaPCxpb41KZguOcC5mGUYD+8RNGcJSlR94=',
      })
      expect(script_tag.to_s).to include('nonce="pJwtLVnwiMaPCxpb41KZguOcC5mGUYD+8RNGcJSlR94="')
    end
  end

  context 'JWT authentication' do
    before(:each) do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
    end
    before(:each) do
      IntercomRails.config.api_secret = 'super-secret'
    end

    it 'enables JWT when configured' do
      IntercomRails.config.jwt.enabled = true
      output = intercom_script_tag({
        user_id: '1234',
        email: 'test@example.com'
      }).to_s
    
      expect(output).to include('intercom_user_jwt')
      expect(output).not_to include('user_hash')
    end

    it 'falls back to user_hash when JWT is disabled' do
      IntercomRails.config.jwt.enabled = false
      output = intercom_script_tag({
        user_id: '1234',
        email: 'test@example.com'
      }).to_s
      
      expect(output).not_to include('intercom_user_jwt')
      expect(output).to include('user_hash')
    end
  end
end
