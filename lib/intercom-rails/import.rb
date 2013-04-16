require 'net/http'
require 'json'
require 'uri'

module IntercomRails

  class Import

    def self.bulk_create_api_endpoint
      host = (ENV['INTERCOM_RAILS_DEV'] ? "http://api.intercom.dev" : "https://api.intercom.io")
      URI.parse(host + "/v1/users/bulk_create")
    end

    def self.run(*args)
      new(*args).run
    end

    attr_reader :uri, :http
    attr_accessor :failed, :total_sent

    def initialize(options = {})
      @uri = Import.bulk_create_api_endpoint
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @failed = []
      @total_sent = 0

      @status_enabled = !!options[:status_enabled]

      if uri.scheme == 'https'
        http.use_ssl = true 
        http.ca_file = File.join(File.dirname(__FILE__), '../data/cacert.pem')
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end

    def assert_runnable
      #raise ImportError, "You can only import your users from your production environment" unless Rails.env.production?
      raise ImportError, "We couldn't find your user class, please set one in config/initializers/intercom_rails.rb" unless user_klass.present?
      info "Found user class: #{user_klass}"
      raise ImportError, "Only ActiveRecord models are supported" unless defined?(ActiveRecord::Base) && (user_klass < ActiveRecord::Base)
      raise ImportError, "Please add an Intercom API Key to config/initializers/intercom.rb" unless IntercomRails.config.api_key.present?
      info "Intercom API key found"
    end

    def run
      assert_runnable

      info "Sending users in batches of #{MAX_BATCH_SIZE}:"
      batches do |batch, number_in_batch|
        failures = send_users(batch)['failed']
        self.failed += failures
        self.total_sent += number_in_batch

        progress '.' * (number_in_batch - failures.count)
        progress 'F' * failures.count
      end
      info "Successfully created #{self.total_sent - self.failed.count} users", :new_line => true
      info "Failed to create #{self.failed.count} #{(self.failed.count == 1) ? 'user' : 'users'}, this is likely due to bad data" unless failed.count.zero?
      
      self
    end

    def total_failed
      self.failed.count
    end

    private
    MAX_BATCH_SIZE = 100
    def batches
      user_klass.find_in_batches(:batch_size => MAX_BATCH_SIZE) do |users|
        users_for_wire = users.map do |u| 
          user_proxy = Proxy::User.new(u)
          next unless user_proxy.valid?
          
          for_wire = user_proxy.to_hash
          companies = Proxy::Company.companies_for_user(user_proxy)
          for_wire.merge!(:companies => companies.map(&:to_hash)) if companies.present?

          for_wire
        end.compact

        yield(prepare_batch(users_for_wire), users_for_wire.count) unless users_for_wire.count.zero?
      end
    end

    def prepare_batch(batch)
      {:users => batch}.to_json
    end

    def user_klass
      if IntercomRails.config.user.model.present?
        IntercomRails.config.user.model.call
      else
        User
      end
    rescue NameError
      # Rails lazy loads constants, so this is how we check 
      nil
    end

    def send_users(users)
      request = Net::HTTP::Post.new(uri.request_uri) 
      request.basic_auth(IntercomRails.config.app_id, IntercomRails.config.api_key)
      request["Content-Type"] = "application/json"
      request.body = users 

      response = perform_request(request)
      JSON.parse(response.body)
    end

    MAX_REQUEST_ATTEMPTS = 3
    def perform_request(request, attempts = 0, error = {})
      if (attempts > 0) && (attempts < MAX_REQUEST_ATTEMPTS)
        sleep(0.5) 
      elsif error.present?
        raise error[:exception] if error[:exception]
        raise exception_for_failed_response(error[:failed_response])
      end

      response = http.request(request)

      return response if successful_response?(response)
      perform_request(request, attempts + 1, :failed_response => response)
    rescue Timeout::Error, Errno::ECONNREFUSED => e
      perform_request(request, attempts + 1, :exception => e)
    end

    def successful_response?(response)
      raise ImportError, "App ID or API Key are incorrect, please check them in config/initializers/intercom.rb" if response.code == '403'
      ['200', '201'].include?(response.code)
    end

    def exception_for_failed_response(response)
      code = response.code
      IntercomAPIError.new("The Intercom API request failed with the code: #{code}, after #{MAX_REQUEST_ATTEMPTS} attempts.")
    end

    def status_enabled?
      @status_enabled
    end

    def progress(str)
      print(str) if status_enabled?
    end

    def info(str, options = {})
      puts "#{"\n" if options[:new_line]}* #{str}" if status_enabled?
    end

  end
end
