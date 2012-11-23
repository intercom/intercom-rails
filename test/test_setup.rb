require 'intercom-rails'
require 'minitest/autorun'
require 'rspec/mocks'
require 'pry'

def dummy_user(options = {})
  user = Struct.new(:email, :name).new
  user.email = options[:email] || 'ben@intercom.io'
  user.name = options[:name] || 'Ben McRedmond'
  user
end

def fake_action_view_class
  klass = Class.new(ActionView::Base)
  klass.class_eval do
    include IntercomRails::ScriptTagHelper
    attr_reader :controller
  end
  klass
end

class Object
  # any_instance.rspec_reset does not work
  def self.unstub_all_instance_methods
    public_instance_methods.each do |method|
      begin
        self.any_instance.unstub(method) 
      rescue RSpec::Mocks::MockExpectationError
        next
      end
    end
  end
end

RSpec::Mocks::setup(Object.new)

module InterTest

  def setup
    IntercomRails::Config.reset!
    super
  end

end
