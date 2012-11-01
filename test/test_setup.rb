require 'intercom-rails'
require 'minitest/autorun'

def fake_action_view_class
  klass = Class.new(ActionView::Base)
  klass.class_eval do
    include IntercomRails::ScriptTagHelper
    attr_reader :controller
  end
  klass
end
