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

end
