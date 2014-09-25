module IntercomRails

  module Proxy

    class Proxy

      def self.class_string
        self.to_s.split('::').last
      end

      def self.inherited(subclass)
        subclass.class_eval do
          attr_reader class_string.downcase.to_s
        end
      end

      attr_reader :search_object, :proxied_object

      def initialize(object_to_proxy, search_object = nil)
        @search_object = search_object
        @proxied_object = instance_variable_set(:"@#{type}", object_to_proxy)
      end

      def to_hash
        data = standard_data.merge(custom_data)
        [:id, :user_id].each do |id_key|
          if(data[id_key] && !data[id_key].is_a?(Numeric))
            data[id_key] = data[id_key].to_s
          end
        end
        DateHelper.convert_dates_to_unix_timestamps(data)
      end

      def standard_data
        proxied_values = self.class.standard_data_proxy_attributes.reduce({}) do |hsh, attribute_name|
          hsh[attribute_name] = send(attribute_name) if send(attribute_name).present?
          hsh
        end

        configured_values = self.class.standard_data_config_attributes.reduce({}) do |hsh, attribute_name|
          next(hsh) unless config_variable_set?(attribute_name)
          hsh.merge(attribute_name => send(attribute_name))
        end

        proxied_values.merge(configured_values)
      end

      def custom_data
        custom_data_from_config.merge custom_data_from_request
      end

      protected

      def self.type
        self.class_string.downcase.to_sym
      end

      def type
        self.class.type
      end

      def self.config(type_override = nil)
        IntercomRails.config.send(type_override || type)
      end

      def config(type_override = nil)
        self.class.config(type_override)
      end

      def config_variable_set?(variable_name)
        config.send(variable_name).present?
      end

      def identity_present?
        self.class.identity_attributes.any? { |attribute_name| proxied_object.respond_to?(attribute_name) && proxied_object.send(attribute_name).present? }
      end

      def self.proxy_delegator(attribute_name, options = {})
        instance_variable_name = :"@_proxy_#{attribute_name}_delegated_value"
        standard_data_proxy_attributes << attribute_name
        identity_attributes << attribute_name if options[:identity]

        send(:define_method, attribute_name) do
          return nil unless proxied_object.respond_to?(attribute_name)

          current_value = instance_variable_get(instance_variable_name)
          return current_value if current_value

          value = proxied_object.send(attribute_name)
          instance_variable_set(instance_variable_name, value)
        end
      end

      def self.config_delegator(attribute_name)
        instance_variable_name = :"@_config_#{attribute_name}_delegated_value"
        standard_data_config_attributes << attribute_name

        send(:define_method, attribute_name) do
          return nil unless config.send(attribute_name).present?

          current_value = instance_variable_get(instance_variable_name)
          return current_value if current_value

          getter = config.send(attribute_name)
          value = getter.call(proxied_object)
          instance_variable_set(instance_variable_name, value)
        end
      end

      def self.identity_attributes
        @_identity_attributes ||= []
      end

      def self.standard_data_proxy_attributes
        @_standard_data_proxy_attributes ||= []
      end

      def self.standard_data_config_attributes
        @_standard_data_config_attributes ||= []
      end

      private

      def custom_data_from_request
        search_object.intercom_custom_data.send(type)
      rescue NoMethodError
        {}
      end

      def custom_data_from_config
        return {} if config.custom_data.blank?
        config.custom_data.reduce({}) do |custom_data, (k,v)|
          custom_data.merge(k => custom_data_value_from_proc_or_symbol(v))
        end
      end

      def custom_data_value_from_proc_or_symbol(proc_or_symbol)
        if proc_or_symbol.kind_of?(Symbol)
          proxied_object.send(proc_or_symbol)
        elsif proc_or_symbol.kind_of?(Proc)
          proc_or_symbol.call(proxied_object)
        end
      end

    end

  end

end
