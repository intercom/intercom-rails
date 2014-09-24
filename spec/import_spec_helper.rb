require 'spec_helper'
require 'active_support/string_inquirer'

module Rails
  def self.env
    ActiveSupport::StringInquirer.new("production")
  end
end

module ActiveRecord
  class Base; end
end

module Mongoid
  module Document
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def all
        @_users ||= User.all
      end

      def limit(*args)
        self
      end

      def skip(*args)
        all
      end
    end
  end
end

class ExampleMongoidUserModel
  include Mongoid::Document
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

  def self.find_in_batches(*args)
    yield(MOCK_USERS.map {|u| new(u)})
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

RSpec.configure do |config|
  config.before(:each) do
    IntercomRails.config.api_key = "abcd"
  end
end

def capturing_stdout
  $stdout.flush
  old = $stdout.dup
  $stdout = @output = StringIO.new

  yield

  $stdout.flush
  @output.string
ensure
  $stdout = old
end

def suppressing_stderr
  old = $stderr.dup
  $stderr = StringIO.new
  yield
ensure
  $stderr = old
end
