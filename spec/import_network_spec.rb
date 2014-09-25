require 'import_spec_helper'
require 'sinatra/base'

class MockIntercom < Sinatra::Base
  set :server, 'thin'

  before do
    content_type 'application/json'
  end

  get '/health_check' do
    content_type 'plain/text'
    'hello world'
  end

  post '/all_successful' do
    {:failed => []}.to_json
  end

  post '/one_failure' do
    {:failed => ['ben@intercom.io']}.to_json
  end

  post '/bad_auth' do
    status 403
    {"error" => {"type" => "not_authenticated", "message" => "HTTP Basic: Access denied."}}.to_json
  end

  post '/500_error' do
    status 500
    {"error" => {"type" => "server_error", "message" => "Danger deploy, gone wrong?"}}.to_json
  end

end

class MockIntercomRunner

  def self.start_mock_intercom
    suppressing_stderr do

      @pid = fork do
        MockIntercom.run!(:port => 46837) do |server|
          server.silent = true
        end
      end

      response = nil
      uri = URI.parse("http://localhost:46837/health_check")

      begin
        response = Net::HTTP.get_response(uri).body until (response == 'hello world')
      rescue Errno::ECONNREFUSED
        sleep(0.5)
        retry
      end
    end
  end

  def self.stop_mock_intercom
    suppressing_stderr do
      Process.kill('INT', @pid)
      Process.wait(@pid) rescue SystemError
    end
  end
end

describe IntercomRails::Import do
  context 'with mock intercom server' do
    before(:all) do
      MockIntercomRunner.start_mock_intercom
    end
    after(:all) do
      MockIntercomRunner.stop_mock_intercom
    end

    let(:import) { IntercomRails::Import.new }

    def set_api_path(path)
      allow(IntercomRails::Import).to receive(:bulk_create_api_endpoint).and_return(URI.parse("http://localhost:46837/#{path}"))
    end

    it 'succeeds with no failures' do
      set_api_path "all_successful"
      import.run
      expect(import.failed).to eq([])
      expect(import.total_sent).to eq(2)
    end

    it 'excludes users if necessary' do
      set_api_path "all_successful"
      IntercomRails.config.user.exclude_if = Proc.new {|user| user.email.start_with?('ben')}
      import.run
      expect(import.failed).to eq([])
      expect(import.total_sent).to eq(1)
    end

    it 'handles one failure' do
      set_api_path "one_failure"
      import.run
      expect(import.failed).to eq(['ben@intercom.io'])
      expect(import.total_sent).to eq(2)
    end

    it 'handles bad_auth' do
      set_api_path "bad_auth"
      expect { import.run }.to raise_error(IntercomRails::ImportError) do |error|
        expect(error.message).to eq("App ID or API Key are incorrect, please check them in config/initializers/intercom.rb")
      end
    end

    it 'handles server errors' do
      set_api_path "500_error"
      expect { import.run }.to raise_error(IntercomRails::IntercomAPIError) do |error|
        expect(error.message).to eq("The Intercom API request failed with the code: 500, after 3 attempts.")
      end
    end
  end
end
