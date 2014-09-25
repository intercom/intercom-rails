require 'intercom-rails'
require 'rspec'
require 'active_support/core_ext/string/output_safety'

def dummy_user(options = {})
  user = Struct.new(:email, :name).new
  user.email = options[:email] || 'ben@intercom.io'
  user.name = options[:name] || 'Ben McRedmond'
  user
end

class DummyBSONId
  def initialize(id)
    @id = id
  end
  def as_json(_)
    {:oid => @id}
  end
  def to_s
    @id
  end
end

def dummy_company(options = {})
  company = Struct.new(:id, :name).new
  company.id = options[:id] || '6'
  company.name = options[:name] || 'Intercom'
  company
end

def fake_action_view_class
  klass = Class.new(Object)
  klass.class_eval do
    include IntercomRails::ScriptTagHelper
    attr_reader :controller
  end
  klass
end

RSpec.configure do |config|
  config.before(:each) do
    IntercomRails::Config.reset!
  end
end
