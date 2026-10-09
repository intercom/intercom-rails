require 'spec_helper'

describe IntercomRails::Proxy::User do
  ProxyUser = IntercomRails::Proxy::User

  DUMMY_USER = dummy_user(:email => 'ciaran@intercom.io', :name => 'Ciaran Lee')

  it 'raises error if no user found' do
    expect { ProxyUser.current_in_context(Object.new) }.to raise_error(IntercomRails::NoUserFoundError)
  end

  it 'finds current_user' do
    object_with_current_user_method = Object.new
    object_with_current_user_method.instance_eval do
      def current_user
        DUMMY_USER
      end
    end

    @user_proxy = ProxyUser.current_in_context(object_with_current_user_method)
    expect(@user_proxy.user).to eq(DUMMY_USER)
  end

  it 'ignores a @user instance variable' do
    object_with_instance_variable = Object.new
    object_with_instance_variable.instance_variable_set(:@user, DUMMY_USER)

    expect { ProxyUser.current_in_context(object_with_instance_variable) }.to raise_error(IntercomRails::NoUserFoundError)
  end

  {
    'current_user' => ->(search_object, user) { search_object.define_singleton_method(:current_user) { user } },
    'config.user.current' => ->(search_object, user) {
      search_object.instance_variable_set(:@user, user)
      IntercomRails.config.user.current = Proc.new { @user }
    },
  }.each do |source, assign|
    it "does not use a user reporting persisted? false from #{source}" do
      unsaved_user = dummy_user(:email => 'not-saved@intercom.io')
      def unsaved_user.persisted?
        false
      end
      search_object = Object.new
      assign.call(search_object, unsaved_user)

      expect { ProxyUser.current_in_context(search_object) }.to raise_error(IntercomRails::NoUserFoundError)
    end
  end

  it 'finds config user' do
    object_from_config = Object.new
    object_from_config.instance_eval do
      def something_esoteric
        DUMMY_USER
      end
    end

    IntercomRails.config.user.current = Proc.new { something_esoteric }
    @user_proxy = ProxyUser.current_in_context(object_from_config)
    expect(@user_proxy.user).to eq(DUMMY_USER)
  end

  it 'raises error if config.user.current is set but does not resolve' do
    IntercomRails.config.user.current = Proc.new { something_esoteric }
    object_with_instance_variable = Object.new
    object_with_instance_variable.instance_eval do
      @user = DUMMY_USER
    end

    expect { ProxyUser.current_in_context(object_with_instance_variable) }.to raise_error(IntercomRails::NoUserFoundError)
  end

  it 'includes custom_data' do
    plan_dummy_user = DUMMY_USER.dup
    plan_dummy_user.instance_eval do
      def plan
        'pro'
      end
    end

    IntercomRails.config.user.custom_data = {
      'plan' => :plan
    }

    @user_proxy = ProxyUser.new(plan_dummy_user)
    expect(@user_proxy.to_hash['plan']).to eql('pro')
  end

  it 'can work with proc custom data' do
    plan_dummy_user = DUMMY_USER.dup
    plan_dummy_user.instance_eval do
      def custom_data
        {
          'plan' => 'pro',
          'registered_at' => Time.at(5),
        }
      end
    end

    IntercomRails.config.user.custom_data = Proc.new { |u| u.custom_data }

    @user_proxy = ProxyUser.new(plan_dummy_user)
    expect(@user_proxy.to_hash['plan']).to eql('pro')
  end

  it 'test can work with symbol custom data' do
    plan_dummy_user = DUMMY_USER.dup
    plan_dummy_user.instance_eval do
      def custom_data
        {
          'plan' => 'pro',
          'registered_at' => Time.at(5),
        }
      end
    end

    IntercomRails.config.user.custom_data = :custom_data

    @user_proxy = ProxyUser.new(plan_dummy_user)
    expect(@user_proxy.to_hash['plan']).to eql('pro')
  end

  it 'converts dates to timestamps' do
    plan_dummy_user = DUMMY_USER.dup
    plan_dummy_user.instance_eval do
      def some_date
        Time.at(5)
      end
    end

    IntercomRails.config.user.custom_data = {
      'some_date' => :some_date
    }

    @user_proxy = ProxyUser.new(plan_dummy_user)
    expect(@user_proxy.to_hash['some_date']).to eq(5)
  end

  it 'is considered valid if user_id or email' do
    expect(ProxyUser.new(DUMMY_USER).valid?).to be(true)
  end

  it 'works with hashes' do
    user = {
      email: 'hash@foo.com'
    }
    expect(ProxyUser.new(user).valid?).to be(true)
  end

  { 'new_record?' => true, 'persisted?' => false, 'new?' => true }.each do |predicate, unsaved_value|
    it "is invalid when the user reports #{predicate} == #{unsaved_value}" do
      user = dummy_user(:email => 'not-saved@intercom.io')
      user.define_singleton_method(predicate) { unsaved_value }
      expect(ProxyUser.new(user).valid?).to be(false)
      user.define_singleton_method(predicate) { !unsaved_value }
      expect(ProxyUser.new(user).valid?).to be(true)
    end
  end

  it 'includes custom data from intercom custom data' do
    object_with_intercom_custom_data = Object.new
    object_with_intercom_custom_data.instance_eval do
      def intercom_custom_data
        Object.new.tap do |o|
          o.instance_eval do
            def user
              {:ponies => :rainbows}
            end
          end
        end
      end
    end

    @user_proxy = ProxyUser.new(DUMMY_USER, object_with_intercom_custom_data)
    expect(@user_proxy.to_hash[:ponies]).to eql(:rainbows)
  end

  it 'is invalid if whiny nil' do
    NilClass.class_eval do
      def id
        raise ArgumentError, "boo"
      end
    end

    search_object = nil
    expect(ProxyUser.new(search_object).valid?).to eq(false)
  end

  it 'gets/sets lead_attributes' do
    IntercomRails.config.user.lead_attributes = %w(utm_source ref_data)
    expect(IntercomRails.config.user.lead_attributes).to eq(["utm_source", "ref_data"])
  end

  it 'gets/sets lead_attributes with valid types' do
    expect { IntercomRails.config.user.lead_attributes = "utm_source" }.to raise_error(ArgumentError)
  end
end
