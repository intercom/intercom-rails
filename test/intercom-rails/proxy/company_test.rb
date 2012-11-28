require 'test_setup'

class CompanyTest < MiniTest::Unit::TestCase

  include InterTest

  Company = IntercomRails::Proxy::Company
  DUMMY_COMPANY = dummy_company

  def test_finds_current_company
    IntercomRails.config.company.current = Proc.new { @app }
    object_with_app_instance_var = Object.new 
    object_with_app_instance_var.instance_variable_set(:@app, DUMMY_COMPANY)

    c = Company.current_in_context(object_with_app_instance_var)
    assert_equal true, c.valid?
    expected_hash = {:id => '6', :name => 'Intercom'}
    assert_equal expected_hash, c.to_hash
  end

  def test_whiny_nil
    NilClass.class_eval do
      def id
        raise ArgumentError, "boo"
      end
    end

    search_object = nil 
    assert_equal false, Company.new(search_object).valid?
  end

end
