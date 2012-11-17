require 'import_test_setup'

class ImportUnitTest < MiniTest::Unit::TestCase 

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

  def test_user_for_wire_returns_nil_if_no_user_id_or_email
    user = Object.new 
    user.instance_eval do
      def name
        "Ben"
      end
    end

    hsh = IntercomRails::Import.new.send(:user_for_wire, user)
    assert_equal hsh, nil
  end

  def test_user_for_wire_returns_hash_if_user_id_or_email
    hsh = IntercomRails::Import.new.send(:user_for_wire, User.first)
    assert_equal({:user_id => 1, :email => "ben@intercom.io", :name => "Ben McRedmond"}, hsh)
  end

  def test_send_users_in_batches_prepares_users_for_wire
    expected_batch = {:users => User.all.map { |u| IntercomRails::Import.new.send(:user_for_wire, u) }}.to_json
    IntercomRails::Import.any_instance.should_receive(:send_users).with(expected_batch).and_return({'failed' => []})
    IntercomRails::Import.run
  end

end
