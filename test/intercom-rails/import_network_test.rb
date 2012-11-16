require 'import_test_setup'
require 'sinatra/base'

class MockIntercom < Sinatra::Base

  before do
    content_type 'application/json'
  end

  post '/all_successful' do
    {:failed => []}.to_json 
  end

end

MockIntercomPID = fork { MockIntercom.run!(:port => 46837) }

class ImportNetworkTest < MiniTest::Unit::TestCase

  def setup
    super 
    @import = Import.new
  end

  def api_path=(path)
    IntercomRails::Import.stub(:bulk_create_api_endpoint) {
      "http://localhost:46837/#{path}"
    }
  end

  def test
    api_path = '/all_successful'
  end

end
