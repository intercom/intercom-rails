module IntercomRails

  module Proxy

    class Company < Proxy

      proxy_delegator :id, :identity => true
      proxy_delegator :name
      proxy_delegator :created_at

      config_delegator :plan
      config_delegator :monthly_spend

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
        return false if company.blank? || company.respond_to?(:new_record?) && company.new_record?
        return false if config.company.exclude_if.present? && config.company.exclude_if.call(company)
        company.present? && identity_present?
      end

    end

  end

end
