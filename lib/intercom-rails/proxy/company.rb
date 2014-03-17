module IntercomRails

  module Proxy

    class Company < Proxy

      proxy_delegator :id, :identity => true
      proxy_delegator :name
      proxy_delegator :created_at

      config_delegator :plan
      config_delegator :monthly_spend

      def self.companies_for_user(user)
        return unless config(:user).company_association.present?
        companies = config(:user).company_association.call(user.user)
        return unless companies.kind_of?(Array)

        companies.map { |company| new(company) }.select { |company_proxy| company_proxy.valid? }
      end

      def self.current_in_context(search_object)
        begin
          if config.current.present?
            company_proxy = new(search_object.instance_eval(&config.current), search_object)
            return company_proxy if company_proxy.valid?
          end
        rescue NameError
        end

        raise NoCompanyFoundError
      end

      def valid?
        company.present? && identity_present?
      end

    end

  end

end
