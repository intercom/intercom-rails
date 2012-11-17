require 'net/http'
require 'json'
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

    attr_reader :uri, :http
    attr_accessor :failed, :total_sent

    def initialize
      @uri = Import.bulk_create_api_endpoint
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @failed = []
      @total_sent = 0

      if uri.scheme == 'https'
        http.use_ssl = true 

        pem = File.read('lib/data/cacert.pem')
        http.ca_file = File.join(File.dirname(__FILE__), '../data/ca_cert.pem')
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end

    def run
      raise ImportError, "You can only import your users from your production environment" unless Rails.env.production?
      raise ImportError, "We couldn't find your user class, please set one in config/initializers/intercom_rails.rb" unless user_klass.present?
      raise ImportError, "Only ActiveRecord models are supported" unless (user_klass < ActiveRecord::Base)
      raise ImportError, "Please add an Intercom API Key to config/initializers/intercom.rb" unless IntercomRails.config.api_key.present?

      batches do |batch|
        self.failed += send_users(batch)['failed']
      end

      self
    end

    def total_failed
      self.failed.count
    end

    private
    MAX_BATCH_SIZE = 100
    def batches
      batch = []

      user_klass.find_each(:batch_size => 100) do |user|
        user = user_for_wire(user)
        batch << user unless user.nil?

        if(batch.count == MAX_BATCH_SIZE)
          yield(prepare_batch(batch))
          batch = []
        end
      end

      yield(prepare_batch(batch)) if batch.present?
    end

    def prepare_batch(batch)
      self.total_sent += batch.count
      {:users => batch}.to_json
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

    def send_users(users, options = {})
      options[:max_retries] ||= 3
      response = nil
      attempts = 0

      request = Net::HTTP::Post.new(uri.request_uri) 
      request.basic_auth(IntercomRails.config.app_id, IntercomRails.config.api_key)
      request["Content-Type"] = "application/json"
      request.body = users 

      begin
        response = http.request(request)
        raise ImportError, "App ID or API Key are incorrect, please check them in config/initializers/intercom.rb" if response.code == '403'
      end while(!successful_response?(response) && 
                ((attempts += 1) < options[:max_retries]))

      JSON.parse(response.body)
    end

    def successful_response?(response)
      ['200', '201'].include?(response.code)
    end

  end
end
