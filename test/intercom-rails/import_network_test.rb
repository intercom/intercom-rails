require 'import_test_setup'
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

class InterRunner < MiniTest::Unit

  self.runner = self.new

  def _run(*args)
    @mock_intercom_pid = start_mock_intercom
    super
  ensure
    Process.kill('INT', @mock_intercom_pid)
    Process.wait(@mock_intercom_pid) rescue SystemError
  end

  private

  def start_mock_intercom
    pid = fork do
      MockIntercom.run!(:port => 46837) do |server|
        server.silent = true
      end
    end

    response = nil
    uri = URI.parse("http://localhost:46837/health_check")

    begin
      response = Net::HTTP.get_response(uri).body until(response == 'hello world')
    rescue Errno::ECONNREFUSED
      sleep(0.5)
      retry
    end

    pid
  end

end

class ImportNetworkTest < InterRunner::TestCase

  include InterTest
  include ImportTest

  def api_path=(path)
    IntercomRails::Import.stub(:bulk_create_api_endpoint) {
      URI.parse("http://localhost:46837/#{path}")
    }

    @import = IntercomRails::Import.new
  end

  def test_empty_failed
    self.api_path = '/all_successful'

    @import.run
    assert_equal [], @import.failed
    assert_equal 2, @import.total_sent
  end

  def test_sets_failed_correctly
    self.api_path = '/one_failure'

    @import.run
    assert_equal ["ben@intercom.io"], @import.failed
    assert_equal 2, @import.total_sent
  end

  def test_raises_import_error_on_bad_auth
    self.api_path = '/bad_auth'

    exception = assert_raises(IntercomRails::ImportError) {
      @import.run
    }

    assert_equal "App ID or API Key are incorrect, please check them in config/initializers/intercom.rb", exception.message
  end

  def test_throws_exception_when_intercom_api_is_being_a_dick
    self.api_path = '/500_error'

    exception = assert_raises(IntercomRails::IntercomAPIError) {
      @import.run
    }

    assert_equal "The Intercom API request failed with the code: 500, after 3 attempts.", exception.message
  end

end
