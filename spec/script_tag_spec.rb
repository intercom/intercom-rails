require 'active_support/time'
require 'spec_helper'
require 'jwt'

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

  context 'integration type' do
    it 'should be rails' do
      script_tag = ScriptTag.new()
      expect(script_tag.intercom_settings[:installation_type]).to eq('rails')
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
      expect(script_tag.csp_sha256).to eq("'sha256-/0mStQPBID1jSuXAoW0YtDqu8JmWUJJ5SdBB2u7Fy90='")
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

  context 'with lead attributes' do
    before do
      IntercomRails.config.user.lead_attributes = [:plan]
      IntercomRails.config.api_secret = 'abcdefgh'
      allow_any_instance_of(IntercomRails::ScriptTag).to receive(:controller).and_return(
        double(intercom_custom_data: double(user: { 'plan' => 'pro' }))
      )
    end

    it 'merges lead attributes with user details' do
      script_tag = ScriptTag.new(
        user_details: { 
          user_id: '1234',
          name: 'Test User'
        }
      )

      expect(script_tag.intercom_settings[:plan]).to eq('pro')
      expect(script_tag.intercom_settings[:user_hash]).to be_present
    end

    it 'preserves existing user details when merging lead attributes' do
      script_tag = ScriptTag.new(
        user_details: { 
          user_id: '1234',
          name: 'Test User',
          email: 'test@example.com'
        }
      )

      expect(script_tag.intercom_settings[:plan]).to eq('pro')
      expect(script_tag.intercom_settings[:name]).to eq('Test User')
      expect(script_tag.intercom_settings[:email]).to eq('test@example.com')
    end
  end

  context 'JWT authentication' do
    before(:each) do
      IntercomRails.config.app_id = 'jwt_test'
      IntercomRails.config.api_secret = 'super-secret'
    end

    it 'does not include JWT when jwt_enabled is false' do
      script_tag = ScriptTag.new(
        user_details: { user_id: '1234' },
        jwt_enabled: false
      )
      expect(script_tag.intercom_settings[:intercom_user_jwt]).to be_nil
    end

    it 'includes JWT when jwt_enabled is true' do
      script_tag = ScriptTag.new(
        user_details: { user_id: '1234' },
        jwt_enabled: true
      )
      expect(script_tag.intercom_settings[:intercom_user_jwt]).to be_present
    end

    it 'does not include user_hash when JWT is enabled' do
      script_tag = ScriptTag.new(
        user_details: { user_id: '1234' },
        jwt_enabled: true
      )
      expect(script_tag.intercom_settings[:user_hash]).to be_nil
    end

    it 'generates a valid JWT with the correct user_id' do
      user_id = '1234'
      script_tag = ScriptTag.new(
        user_details: { user_id: user_id },
        jwt_enabled: true
      )
      
      jwt = script_tag.intercom_settings[:intercom_user_jwt]
      decoded_payload = JWT.decode(jwt, 'super-secret', true, { algorithm: 'HS256' })[0]
      
      expect(decoded_payload['user_id']).to eq(user_id)
    end

    it 'does not generate JWT when user_id is missing' do
      script_tag = ScriptTag.new(
        user_details: { email: 'test@example.com' },
        jwt_enabled: true
      )
      expect(script_tag.intercom_settings[:intercom_user_jwt]).to be_nil
    end

    it 'does not generate JWT when api_secret is missing' do
      IntercomRails.config.api_secret = nil
      script_tag = ScriptTag.new(
        user_details: { user_id: '1234' },
        jwt_enabled: true
      )
      expect(script_tag.intercom_settings[:intercom_user_jwt]).to be_nil
    end

    it 'removes user_id from payload when using JWT' do
      script_tag = ScriptTag.new(
        user_details: { 
          user_id: '1234',
          email: 'test@example.com',
          name: 'Test User'
        },
        jwt_enabled: true
      )
      
      expect(script_tag.intercom_settings[:intercom_user_jwt]).to be_present
      expect(script_tag.intercom_settings[:user_id]).to be_nil
      expect(script_tag.intercom_settings[:email]).to eq('test@example.com')
      expect(script_tag.intercom_settings[:name]).to eq('Test User')
    end

    it 'keeps user_id in payload when not using JWT' do
      script_tag = ScriptTag.new(
        user_details: { 
          user_id: '1234',
          email: 'test@example.com',
          name: 'Test User'
        },
        jwt_enabled: false
      )
      
      expect(script_tag.intercom_settings[:user_id]).to eq('1234')
      expect(script_tag.intercom_settings[:email]).to eq('test@example.com')
      expect(script_tag.intercom_settings[:name]).to eq('Test User')
    end

    context 'with signed_user_fields' do
      before do
        IntercomRails.config.jwt.signed_user_fields = [:email, :name, :plan, :team_id]
      end

      it 'includes configured fields in JWT when present' do
        script_tag = ScriptTag.new(
          user_details: { 
            user_id: '1234',
            email: 'test@example.com',
            plan: 'pro',
            team_id: 'team_123',
            company_size: 100
          },
          jwt_enabled: true
        )
        
        jwt = script_tag.intercom_settings[:intercom_user_jwt]
        decoded_payload = JWT.decode(jwt, 'super-secret', true, { algorithm: 'HS256' })[0]
        
        expect(decoded_payload['user_id']).to eq('1234')
        expect(decoded_payload['email']).to eq('test@example.com')
        expect(decoded_payload['plan']).to eq('pro')
        expect(decoded_payload['team_id']).to eq('team_123')
        expect(decoded_payload['company_size']).to be_nil
        
        expect(script_tag.intercom_settings[:user_id]).to be_nil
        expect(script_tag.intercom_settings[:email]).to be_nil
        expect(script_tag.intercom_settings[:plan]).to be_nil
        expect(script_tag.intercom_settings[:team_id]).to be_nil
        expect(script_tag.intercom_settings[:company_size]).to eq(100)
      end

      it 'handles missing configured fields gracefully' do
        script_tag = ScriptTag.new(
          user_details: { 
            user_id: '1234',
            email: 'test@example.com'
          },
          jwt_enabled: true
        )
        
        jwt = script_tag.intercom_settings[:intercom_user_jwt]
        decoded_payload = JWT.decode(jwt, 'super-secret', true, { algorithm: 'HS256' })[0]
        
        expect(decoded_payload['user_id']).to eq('1234')
        expect(decoded_payload['email']).to eq('test@example.com')
        expect(decoded_payload['name']).to be_nil
      end
    
      it 'respects empty signed_user_fields configuration' do
        IntercomRails.config.jwt.signed_user_fields = []
        script_tag = ScriptTag.new(
          user_details: { 
            user_id: '1234',
            email: 'test@example.com',
            name: 'Test User'
          },
          jwt_enabled: true
        )
        
        jwt = script_tag.intercom_settings[:intercom_user_jwt]
        decoded_payload = JWT.decode(jwt, 'super-secret', true, { algorithm: 'HS256' })[0]
        
        expect(decoded_payload['user_id']).to eq('1234')
        expect(decoded_payload['email']).to be_nil
        expect(decoded_payload['name']).to be_nil
        

        expect(script_tag.intercom_settings[:email]).to eq('test@example.com')
        expect(script_tag.intercom_settings[:name]).to eq('Test User')
      end
    end

    context 'JWT expiry' do
      it 'includes expiry when configured' do
        IntercomRails.config.jwt.expiry = 12.hours
        script_tag = ScriptTag.new(
          user_details: { user_id: '1234' },
          jwt_enabled: true
        )
        
        jwt = script_tag.intercom_settings[:intercom_user_jwt]
        decoded_payload = JWT.decode(jwt, 'super-secret', true, { algorithm: 'HS256' })[0]
        
        expect(decoded_payload['exp']).to be_within(5).of(12.hours.from_now.to_i)
      end

      it 'omits expiry when not configured' do
        IntercomRails.config.jwt.expiry = nil
        script_tag = ScriptTag.new(
          user_details: { user_id: '1234' },
          jwt_enabled: true
        )
        
        jwt = script_tag.intercom_settings[:intercom_user_jwt]
        decoded_payload = JWT.decode(jwt, 'super-secret', true, { algorithm: 'HS256' })[0]
        
        expect(decoded_payload).not_to have_key('exp')
      end

      it 'allows overriding expiry via options' do
        IntercomRails.config.jwt.expiry = 24.hours
        script_tag = ScriptTag.new(
          user_details: { user_id: '1234' },
          jwt_enabled: true,
          jwt_expiry: 1.hour
        )
        
        jwt = script_tag.intercom_settings[:intercom_user_jwt]
        decoded_payload = JWT.decode(jwt, 'super-secret', true, { algorithm: 'HS256' })[0]
        
        expect(decoded_payload['exp']).to be_within(5).of(1.hour.from_now.to_i)
      end
    end
  end

end
