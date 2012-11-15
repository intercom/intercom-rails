require 'test_setup'
require 'active_support/string_inquirer'

class Rails
  def self.env
    ActiveSupport::StringInquirer.new("production")
  end
end

module ActiveRecord
  class Base; end
end

class User

  attr_reader :id, :email, :name

  def initialize(options = {})
    options.each do |k,v|
      instance_variable_set(:"@#{k}", v)
    end
  end

  MOCK_USERS = [
    {:id => 1, :email => "ben@intercom.io", :name => "Ben McRedmond"},
    {:id => 2, :email => "ciaran@intercom.io", :name => "Ciaran Lee"}
  ]

  def self.find_each(*args)
    MOCK_USERS.each do |user|
      yield new(user)
    end
  end

  def self.all
    MOCK_USERS.map { |u| new(u) }
  end

  def self.first
    new(MOCK_USERS.first)
  end

  def self.<(other)
    other == ActiveRecord::Base
  end

end

class ImportTest < MiniTest::Unit::TestCase 

  def setup
    IntercomRails.config.stub(:api_key).and_return("abcd")
  end

  def teardown
    Rails.rspec_reset
    User.rspec_reset
    IntercomRails::Import.rspec_reset
    IntercomRails::Import.unstub_all_instance_methods
  end

  def test_run_with_wrong_rails_env
    Rails.stub(:env).and_return ActiveSupport::StringInquirer.new("development")

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end

    assert_equal exception.message, "You can only import your users from your production environment"
  end

  def test_run_with_no_user_class
    IntercomRails::Import.any_instance.stub(:user_klass).and_return(nil)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "We couldn't find your user class, please set one in config/initializers/intercom_rails.rb"
  end

  def test_run_with_non_activerecord_user_class
    IntercomRails::Import.any_instance.stub(:user_klass).and_return(Class)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "intercom:import currently only supports ActiveRecord models"
  end

  def test_run_with_no_api_key
    IntercomRails.config.stub(:api_key).and_return(nil)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "Please add an Intercom API Key to config/initializers/intercom.rb"
  end

  def test_user_for_wire_returns_nil_if_no_user_id_or_email
    user = Object.new 
    user.instance_eval do
      def name
        "Ben"
      end
    end

    hsh = IntercomRails::Import.new.user_for_wire(user)
    assert_equal hsh, nil
  end

  def test_user_for_wire_returns_hash_if_user_id_or_email
    hsh = IntercomRails::Import.new.user_for_wire(User.first)
    assert_equal({:user_id => 1, :email => "ben@intercom.io", :name => "Ben McRedmond"}, hsh)
  end

  def test_send_users_in_batches_prepares_users_for_Wire
    expected_batch = User.all.map { |u| IntercomRails::Import.new.user_for_wire(u) }
    IntercomRails::Import.any_instance.should_receive(:send_user_batch).with(expected_batch)
    IntercomRails::Import.run
  end

end
