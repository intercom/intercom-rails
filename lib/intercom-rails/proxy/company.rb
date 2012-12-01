module IntercomRails

  module Proxy

    class Company < Proxy

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
        company.present? && company.respond_to?(:id) && company.id.present?
      end

      def standard_data
        hsh = {}
        hsh[:id] = company.id
        hsh[:name] = company.name if attribute_present?(:name) 
        hsh[:created_at] = company.created_at if attribute_present?(:created_at) 
        hsh
      end

    end

  end

end
