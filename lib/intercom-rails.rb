require 'intercom-rails/script_tag_helper'
require 'intercom-rails/script_tag_helper_call_tracker'
require 'intercom-rails/auto_include_filter'
require 'intercom-rails/config'
require 'intercom-rails/railtie' if defined? Rails

module IntercomRails

  def self.config
    block_given? ? yield(Config) : Config
  end

end
