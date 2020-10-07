require 'active_support/time'
require 'spec_helper'

describe IntercomRails::ScriptTag do
  ScriptTag = IntercomRails::ScriptTag
  before(:each) do
    IntercomRails.config.app_id = 'script_tag_test'
  end

  it 'should output html_safe?' do
    expect(ScriptTag.new({}).to_s.html_safe?).to be(true)
  end

  it 'should convert times to unix timestamps' do
    time = Time.new(1993, 02, 13)
    top_level_time = ScriptTag.new(:user_details => {:created_at => time})
    expect(top_level_time.intercom_settings[:created_at]).to eq(time.to_i)

    now = Time.now
    nested_time = ScriptTag.new(:user_details => {:custom_data => {"something" => now}})
    expect(nested_time.intercom_settings[:custom_data]["something"]).to eq(now.to_i)

    utc_time = Time.utc(2013, 04, 03)
    time_zone = ActiveSupport::TimeZone.new('London')
    time_with_zone = ActiveSupport::TimeWithZone.new(utc_time, time_zone)
    time_from_time_with_zone = ScriptTag.new(:user_details => {:created_at => time_with_zone})

    expect(time_from_time_with_zone.intercom_settings[:created_at]).to eq(utc_time.to_i)
  end
  context 'session' do
    before do
      IntercomRails.config.session_duration = 60000
    end
    it 'displays session_duration' do
      script_tag = ScriptTag.new()
      expect(script_tag.intercom_settings[:session_duration]).to eq(60000)
    end
  end

  it 'strips out nil entries for standard attributes' do
    %w(name email user_id).each do |standard_attribute|
      with_value = ScriptTag.new(:user_details => {standard_attribute => 'value'})
      expect(with_value.intercom_settings[standard_attribute]).to eq('value')

      with_nil_value = ScriptTag.new(:user_details => {standard_attribute.to_sym => nil})
      expect(with_nil_value.intercom_settings.has_key?(standard_attribute.to_sym)).to be(false)

      with_nil_value = ScriptTag.new(:user_details => {standard_attribute => nil})
      expect(with_nil_value.intercom_settings.has_key?(standard_attribute.to_sym)).to be(false)
    end
  end

  it 'should escape html attributes' do
    nasty_email = "</script><script>alert('sup?');</script>"
    script_tag = ScriptTag.new(:user_details => {:email => nasty_email})
    expect(script_tag.to_s).not_to include(nasty_email)
  end

  it 'should escape html attributes in app_id' do
    email = "bob@foo.com"
    before = IntercomRails.config.app_id
    nasty_app_id = "</script><script>alert('sup?');</script>"
    IntercomRails.config.app_id = nasty_app_id
    script_tag = ScriptTag.new(:user_details => {:email => email})
    expect(script_tag.to_s).not_to include(nasty_app_id)
    IntercomRails.config.app_id = before
  end

  context 'Encrypted Mode' do
    it 'sets an encrypted payload' do
      iv = Base64.decode64("2X0G4PoOBn9+wdf8")
      script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io'}, :secret => 'abcdefgh', :encrypted_mode => true, :initialization_vector => iv)
      result = script_tag.to_s
      expect(result).to_not include("ciaran@intercom.io")
      expect(result).to match(/window\.intercomEncryptedPayload = \"[^\"\n]+\"/)
    end

    it "#plaintext_settings" do
      script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io'}, :secret => 'abcdefgh', :encrypted_mode => true)
      expect(script_tag.plaintext_settings).to_not include(:email)
      script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io'}, :secret => 'abcdefgh', :encrypted_mode => false)
      expect(script_tag.plaintext_settings).to include(:email)
    end

    it "#encrypted_settings" do
      script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io'}, :secret => 'abcdefgh', :encrypted_mode => true)
      expect(script_tag.encrypted_settings).to match(/[^\"\n]+/)
    end
  end

  context 'Identity Verification - user_hash' do

    it 'computes user_hash using email when email present, and user_id blank' do
      script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io'}, :secret => 'abcdefgh')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', 'ciaran@intercom.io'))
      script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io', :user_id => nil}, :secret => 'abcdefgh')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', 'ciaran@intercom.io'))
      # script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io', :user_id => ''}, :secret => 'abcdefgh')
      # expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', 'ciaran@intercom.io')) # todo - test what server behavior is...
    end

    it 'computes user_hash using user_id when user_id present' do
      script_tag = ScriptTag.new(:user_details => {:user_id => '1234'}, :secret => 'abcdefgh')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', '1234'))
      script_tag = ScriptTag.new(:user_details => {:user_id => '1234', :email => nil}, :secret => 'abcdefgh')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', '1234'))
      script_tag = ScriptTag.new(:user_details => {:user_id => '1234', :email => ''}, :secret => 'abcdefgh')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', '1234'))
    end

    it 'computes user_hash using user_id when both present' do
      script_tag = ScriptTag.new(:user_details => {:user_id => '1234', :email => 'ciaran@intercom.io'}, :secret => 'abcdefgh')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', '1234'))
    end

    it 'emits user_hash when api_secret set on config' do
      IntercomRails.config.api_secret = 'abcdefgh'
      script_tag = ScriptTag.new(:user_details => {:email => 'ben@intercom.io'})
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('abcdefgh', 'ben@intercom.io'))
    end

    it 'favors passed seret over config api_secret' do
      IntercomRails.config.api_secret = 'abcd'
      script_tag = ScriptTag.new(:user_details => {:email => 'ben@intercom.io'}, :secret => '1234')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('1234', 'ben@intercom.io'))
      script_tag = ScriptTag.new(:user_details => {:user_id => 5678}, :secret => '1234')
      expect(script_tag.intercom_settings[:user_hash]).to eq(sha256_hmac('1234', '5678'))
    end

    def sha256_hmac(secret, input)
      OpenSSL::HMAC.hexdigest("sha256", secret, input)
    end
  end

  context 'inbox style' do
    it 'knows about :default' do
      IntercomRails.config.inbox.style = :default
      expect(ScriptTag.new.intercom_settings['widget']).to eq({'activator' => '#IntercomDefaultWidget'})
    end
    it 'knows about :custom' do
      IntercomRails.config.inbox.style = :custom
      expect(ScriptTag.new.intercom_settings['widget']).to eq({'activator' => '#Intercom'})
    end
    it 'knows about :custom_activator' do
      IntercomRails.config.inbox.style = :custom
      IntercomRails.config.inbox.custom_activator = '.intercom'
      expect(ScriptTag.new.intercom_settings['widget']).to eq({'activator' => '.intercom'})
    end
    it 'knows about :hide_default_launcher' do
      IntercomRails.config.hide_default_launcher = true
      expect(ScriptTag.new.intercom_settings['hide_default_launcher']).to eq(true)
    end
    it 'knows about :api_base' do
      IntercomRails.config.api_base = "https://abcde1.intercom-messenger.com"
      expect(ScriptTag.new.intercom_settings['api_base']).to eq("https://abcde1.intercom-messenger.com")
    end
  end

  context 'company' do
    let(:company) { dummy_company }
    it 'discovers and includes company' do
      IntercomRails.config.company.current = Proc.new { @app }
      controller_with_app_variable = Object.new
      controller_with_app_variable.instance_eval do
        @app = dummy_company
      end

      script_tag = ScriptTag.new(:controller => controller_with_app_variable, :find_current_company_details => true)
      expect(script_tag.intercom_settings[:company]).to eq({'id' => '6', 'name' => 'Intercom'})
    end
  end

  context 'without user details' do
    it 'should be valid when show_everywhere is set' do
      script_tag = ScriptTag.new(:show_everywhere => true)
      expect(script_tag.valid?).to eq(true)
    end

    it 'should not be valid when show_everywhere is not set' do
      script_tag = ScriptTag.new()
      expect(script_tag.valid?).to eq(false)
    end
  end

  context 'content security policy support' do
    it 'returns a valid sha256 hash for the CSP header' do
      #
      # If default values change, re-generate the string below using this one
      # liner:
      #  echo "sha256-$(echo -n "js code" | openssl dgst -sha256 -binary | openssl base64)"
      # or an online service like https://report-uri.io/home/hash/
      #
      # For instance:
      #  echo "sha256-$(echo -n "alert('hello');" | openssl dgst -sha256 -binary | openssl base64)"
      #  sha256-gj4FLpwFgWrJxA7NLcFCWSwEF/PMnmWidszB6OONAAo=
      #
      script_tag = ScriptTag.new(:user_details => {
        :app_id => 'csp_sha_test',
        :email => 'marco@intercom.io',
        :user_id => 'marco',
      })
      expect(script_tag.csp_sha256).to eq("'sha256-qLRbekKD6dEDMyLKPNFYpokzwYCz+WeNPqJE603mT24='")
    end

    it 'inserts a valid nonce if present' do
      script_tag = ScriptTag.new(:user_details => {
        :app_id => 'csp_sha_test',
        :email => 'marco@intercom.io',
        :user_id => 'marco',
      },
        :nonce => 'pJwtLVnwiMaPCxpb41KZguOcC5mGUYD+8RNGcJSlR94=')
      expect(script_tag.to_s).to include('nonce="pJwtLVnwiMaPCxpb41KZguOcC5mGUYD+8RNGcJSlR94="')
    end

    it 'does not insert a nasty nonce if present' do
      script_tag = ScriptTag.new(:user_details => {
        :app_id => 'csp_sha_test',
        :email => 'marco@intercom.io',
        :user_id => 'marco',
      },
        :nonce => '>alert(1)</script><script>')
      expect(script_tag.to_s).not_to include('>alert(1)</script><script>')
    end
  end

  context 'request specific parameters' do
    it 'does not complain when no controller is found' do
      script_tag = ScriptTag.new(utm_source: 'google')
      expect(script_tag.intercom_settings[:utm_source]).to eq(nil)
    end

    it 'accepts request specific defined lead attributes and rejects rest' do
      IntercomRails.config.user.lead_attributes = %w(utm_source ref_data)

      controller_with_request = Object.new
      controller_with_request.instance_eval do
        def intercom_custom_data
          Object.new.tap do |o|
            o.instance_eval do
              def user
                {
                  utm_source: 'google',
                  ref_data: 12345,
                  ad_data: 'something1234'
                }
              end
            end
          end
        end
      end

      script_tag = ScriptTag.new(controller: controller_with_request)

      expect(script_tag.intercom_settings[:utm_source]).to eq('google')
      expect(script_tag.intercom_settings[:ref_data]).to eq(12345)
      # Rejects
      expect(script_tag.intercom_settings[:ad_data]).to eq(nil)
    end

  end

end
