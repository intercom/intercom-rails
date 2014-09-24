require 'active_support/time'
require 'spec_helper'

describe IntercomRails::ScriptTag do
  ScriptTag = IntercomRails::ScriptTag
  before(:each) do
    IntercomRails.config.app_id = 'script_tag_test'
  end

  it 'should output html_safe?' do
    expect(ScriptTag.generate({}).html_safe?).to be(true)
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
    expect(script_tag.output).not_to include(nasty_email)
  end

  context 'secure mode - user_hash' do

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
end
