require 'active_support/time'
require 'spec_helper'

describe IntercomRails do
  it 'gets/sets app_id' do
    IntercomRails.config.app_id = "1234"
    expect(IntercomRails.config.app_id).to eq("1234")
  end

  it 'gets/sets session_duration' do
    IntercomRails.config.session_duration = 60000
    expect(IntercomRails.config.session_duration).to eq(60000)
  end

  it 'gets/sets current_user' do
    current_user = Proc.new { @blah }
    IntercomRails.config.user.current = current_user
    expect(IntercomRails.config.user.current).to eq(current_user)
  end

  it 'gets/sets several current_user' do
    current_user = [ Proc.new { @blah }, Proc.new { @bloh }, Proc.new{ @bleh } ]
    IntercomRails.config.user.current = current_user
    expect(IntercomRails.config.user.current).to eq(current_user)
  end

  it 'gets/sets custom_data' do
    custom_data_config = {
      'foo' => Proc.new {},
      'bar' => :method_name
    }
    IntercomRails.config.user.custom_data = custom_data_config
    expect(IntercomRails.config.user.custom_data).to eq(custom_data_config)
  end

  it 'gets/sets company custom_data' do
    custom_data_config = {
      'the_local' => Proc.new { 'club 93' }
    }
    IntercomRails.config.company.custom_data = custom_data_config
    expect(IntercomRails.config.company.custom_data).to eq(custom_data_config)
  end

  it 'gets/sets inbox style' do
    IntercomRails.config.inbox.style = :custom
    expect(IntercomRails.config.inbox.style).to eq(:custom)
  end

  it 'gets/sets custom_activator' do
    IntercomRails.config.inbox.custom_activator = '.intercom'
    expect(IntercomRails.config.inbox.custom_activator).to eq('.intercom')
  end

  it 'gets/sets hide_default_launcher' do
    IntercomRails.config.hide_default_launcher = true
    expect(IntercomRails.config.hide_default_launcher).to eq(true)
  end

  it 'gets/sets Encrypted Mode' do
    IntercomRails.config.encrypted_mode = true
    expect(IntercomRails.config.encrypted_mode).to eq(true)
  end

  it 'raises error if current user not a proc' do
    expect { IntercomRails.config.user.current = 1 }.to raise_error(ArgumentError)
  end

  it 'allows config in block form' do
    IntercomRails.config do |config|
      config.app_id = "4567"
    end
    expect(IntercomRails.config.app_id).to eq("4567")
  end

  it 'rejects non proc/symbol attributes' do
    expect { IntercomRails.config.user.custom_data = {'bar' => 'heyheyhey!'} }.to raise_error(ArgumentError) do |error|
      expect(error.message).to eq("all custom_data attributes should be either a Proc or a symbol")
    end
  end

  it 'setting custom data with proc' do
    custom_data = {
      'foo' => 'bar',
      'bar' => 'baz'
    }
    custom_data_config = Proc.new { custom_data }

    IntercomRails.config.user.custom_data = custom_data_config
    expect(custom_data).to eql(IntercomRails.config.user.custom_data.call)
  end


  it 'can be reset!' do
    IntercomRails.config.inbox.style = :custom
    IntercomRails.config.user.custom_data = {'muffin' => :muffin}
    IntercomRails.config.reset!
    expect(IntercomRails.config.user.custom_data).to eq(nil)
    expect(IntercomRails.config.inbox.style).to eq(nil)
  end

  it 'prints a deprecation warning when #api_key= is used' do
    expect do
      IntercomRails.config.api_key = "foo"
    end.to output(/no longer supported/).to_stderr
  end

  it 'prints a deprecation warning when user.company_association= is used' do
    expect do
      IntercomRails.config.user.company_association = Proc.new { [] }
    end.to output(/no longer supported/).to_stderr
  end
end
