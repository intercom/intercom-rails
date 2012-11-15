require 'net/http'
require 'uri'

module IntercomRails
  class ImportError < StandardError; end

  class Import

    def self.bulk_create_api_endpoint
      host = (ENV['INTERCOM_RAILS_DEV'] ? "http://intercom.dev" : "https://api.intercom.io")
      URI.parse(host + "api/v1/users/bulk_create")
    end

    def self.run
      new.run
    end

    def run
      raise ImportError, "You can only import your users from your production environment" unless Rails.env.production?
      raise ImportError, "We couldn't find your user class, please set one in config/initializers/intercom_rails.rb" unless user_klass.present?
      raise ImportError, "intercom:import currently only supports ActiveRecord models" unless (user_klass < ActiveRecord::Base)
      raise ImportError, "Please add an Intercom API Key to config/initializers/intercom.rb" unless IntercomRails.config.api_key.present?

      send_users_in_batches
    end

    def send_users_in_batches
      batch = []

      user_klass.find_each(:batch_size => 100) do |user|
        batch << user_for_wire(user)
        
        if(batch.length == 100)
          send_user_batch(batch)
          batch = []
        end
      end
      
      send_user_batch(batch) unless batch.length.zero?
    end

    def send_user_batch(batch)
      batch = batch.compact.to_json
    end

    def user_for_wire(user)
      wired = {}.tap do |hsh|
        hsh[:user_id] = user.id if user.respond_to?(:id) && user.id.present?
        hsh[:email] = user.email if user.respond_to?(:email) && user.email.present?
        hsh[:name] = user.name if user.respond_to?(:name) && user.name.present?
        # hsh[:custom_data] = user_attributes.reduce({}) { |hsh,attribute| hsh.merge(attribute => user.send(:attribute)) }
      end

      (wired[:user_id] || wired[:email]) ? wired : nil
    end

    def user_klass
      if IntercomRails.config.user_model.present?
        IntercomRails.config.user_model.call
      else
        User if defined?(User)
      end
    end

  end
end
