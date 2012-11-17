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

  post '/return_body' do
    request.body
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

  include ImportTest

  def api_path=(path)
    IntercomRails::Import.stub(:bulk_create_api_endpoint) {
      URI.parse("http://localhost:46837/#{path}")
    }

    @import = IntercomRails::Import.new
  end

  def test_posts_json_hash
  end

  def test_total_sent
    self.api_path = '/all_successful'

    @import.send_users_in_batches
    assert_equal 2, @import.total_sent
  end

end
