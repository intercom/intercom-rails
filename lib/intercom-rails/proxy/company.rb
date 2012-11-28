module IntercomRails

  module Proxy

    class Company < Proxy

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
        company.respond_to?(:id) && company.id.present?
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
