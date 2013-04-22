require 'import_test_setup'

class ImportUnitTest < MiniTest::Unit::TestCase 

  include InterTest
  include ImportTest

  def test_run_with_wrong_rails_env
    Rails.stub(:env).and_return ActiveSupport::StringInquirer.new("development")

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end

    assert_equal exception.message, "You can only import your users from your production environment"
  end

  def test_run_with_no_user_class
    IntercomRails::Import.any_instance.stub(:user_klass).and_return(nil)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "We couldn't find your user class, please set one in config/initializers/intercom_rails.rb"
  end

  def test_run_with_non_activerecord_user_class
    IntercomRails::Import.any_instance.stub(:user_klass).and_return(Class)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "Only ActiveRecord models are supported"
  end

  def test_run_with_no_api_key
    IntercomRails.config.stub(:api_key).and_return(nil)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "Please add an Intercom API Key to config/initializers/intercom.rb"
  end

  def test_status_output
    @import = IntercomRails::Import.new(:status_enabled => true)
    @import.stub(:send_users).and_return('failed' => [1])
    @import.stub(:hashify_batch).and_return([1,1,1])

    $stdout.flush
    @old_stdout = $stdout.dup
    $stdout = @output = StringIO.new

    @import.run
    expected_output = <<-output
* Found user class: User
* Intercom API key found
* Sending users in batches of 1000:
..F
* Successfully created 2 users
* Failed to create 1 user, this is likely due to bad data
output
    $stdout.flush

    assert_equal expected_output, @output.string
  ensure
    $stdout = @old_stdout
  end

  def test_prepares_companies
    @import = IntercomRails::Import.new

    u = dummy_user
    u.instance_eval do
      def apps
        [dummy_company]
      end
    end

    User.stub(:find_in_batches).and_yield([u])

    IntercomRails.config.user.company_association = Proc.new { |user| user.apps }

    prepared_users = nil
    @import.stub(:send_users) do |users_json|
      prepared_users = JSON.parse(users_json)['users']
      {'failed' => []}
    end

    @import.run

    assert_equal 1, prepared_users[0]['companies'].length
    User.rspec_reset
  end

  def test_eager_loads_user_associations
    @import = IntercomRails::Import.new
    stub_send_users

    User.stub(:reflect_on_all_associations).and_return([MockAssociation.new(:hobbies)])
    User.should_receive(:includes).with([:hobbies]).and_return(User)
    @import.run
  end

  def test_finds_company_association
    @import = IntercomRails::Import.new
    stub_send_users

    IntercomRails.config.user.company_association = Proc.new { |user| user.company }
    IntercomRails.config.company.model = Proc.new { Company }

    User.stub(:reflect_on_all_associations).and_return([MockAssociation.new(:hobbies), MockAssociation.new(:company)])

    Company.should_receive(:reflect_on_all_associations).and_return([MockAssociation.new(:projects)])
    User.should_receive(:includes).with([:hobbies, {:company => [:projects]}]).and_return(User)

    @import.run
  end

  private
  def stub_send_users
    @import.stub(:send_users).and_return({'failed' => []})
  end

end
