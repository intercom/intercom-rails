require 'spec_helper'

describe IntercomRails::Proxy::Company do
  ProxyCompany = IntercomRails::Proxy::Company
  DUMMY_COMPANY = dummy_company

  it 'finds current company' do
    IntercomRails.config.company.current = Proc.new { @app }
    object_with_app_instance_var = Object.new
    object_with_app_instance_var.instance_variable_set(:@app, DUMMY_COMPANY)

    c = ProxyCompany.current_in_context(object_with_app_instance_var)
    expect(c.valid?).to eq(true)
    expected_hash = {:id => '6', :name => 'Intercom'}
    expect(c.to_hash).to eq(expected_hash)
  end

  it 'is invalid if whiny nil' do
    NilClass.class_eval do
      def id
        raise ArgumentError, "boo"
      end
    end

    search_object = nil
    expect(ProxyCompany.new(search_object).valid?).to eq(false)
  end

  it 'does companies for user' do
    IntercomRails.config.user.company_association = Proc.new { |user| user.apps }
    test_user = dummy_user
    test_user.instance_eval do
      def apps
        [DUMMY_COMPANY, dummy_company(:name => "Prey", :id => "800")]
      end
    end

    companies = ProxyCompany.companies_for_user(IntercomRails::Proxy::User.new(test_user))
    expect(companies.length).to eq(2)
    expect(companies.map(&:company).map(&:name)).to eq(["Intercom", "Prey"])
  end
end
