require 'intercom-rails/current_user'
require 'intercom-rails/script_tag'
require 'intercom-rails/script_tag_helper'
require 'intercom-rails/auto_include_filter'
require 'intercom-rails/config'
require 'intercom-rails/import'
require 'intercom-rails/railtie' if defined? Rails

module IntercomRails

  def self.config
    block_given? ? yield(Config) : Config
  end

end
