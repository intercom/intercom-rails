require 'active_support/inflector'

module IntercomRails

  class Config
    # Validators (moved outside of class << self for accessibility)
    CUSTOM_DATA_VALIDATOR = Proc.new do |custom_data, field_name|
      case custom_data
      when Hash
        unless custom_data.values.all? { |value| value.kind_of?(Proc) || value.kind_of?(Symbol) }
          raise ArgumentError, "all custom_data attributes should be either a Proc or a symbol"
        end
      when Proc, Symbol
      else
        raise ArgumentError, "#{field_name} custom_data should be either be a hash or a Proc/Symbol that returns a hash when called"
      end
    end

    ARRAY_VALIDATOR = Proc.new do |data, field_name|
      raise ArgumentError, "#{field_name} data should be an Array" unless data.kind_of?(Array)
    end

    IS_PROC_VALIDATOR = Proc.new do |value, field_name|
      raise ArgumentError, "#{field_name} is not a proc" unless value.kind_of?(Proc)
    end

    IS_ARAY_OF_PROC_VALIDATOR = Proc.new do |data, field_name|
      raise ArgumentError, "#{field_name} data should be a proc or an array of proc" unless data.all? { |value| value.kind_of?(Proc)}
    end

    IS_PROC_OR_ARRAY_OF_PROC_VALIDATOR = Proc.new do |data, field_name|
      if data.kind_of?(Array)
        IS_ARAY_OF_PROC_VALIDATOR.call(data, field_name)
      else
        IS_PROC_VALIDATOR.call(data, field_name)
      end
    end

    class << self

      # Helper to create accessor with validation
      def config_accessor(name, validator: nil)
        attr_name = :"@#{name}"
        
        # Define getter
        define_singleton_method(name) do
          instance_variable_get(attr_name)
        end
        
        # Define setter with validation
        define_singleton_method("#{name}=") do |value|
          if validator
            field_name = @underscored_class_name ? "#{@underscored_class_name}.#{name}" : name.to_s
            args = validator.arity > 1 ? [value, field_name] : [value]
            validator.call(*args)
          end
          instance_variable_set(attr_name, value)
        end
      end

      def reset!
        to_reset = [self] + constants.select { |c| const_get(c).is_a?(Class) && const_get(c) < Config }.map { |c| const_get(c) }
        
        to_reset.each do |configer|
          configer.instance_variables.each do |var|
            configer.send(:remove_instance_variable, var)
          end
        end
      end

      def api_key=(*)
        warn "Setting an Intercom API key is no longer supported; remove the `config.api_key = ...` line from config/initializers/intercom.rb"
      end
    end

    # Main configuration options
    config_accessor :app_id
    config_accessor :session_duration
    config_accessor :api_secret
    config_accessor :library_url
    config_accessor :enabled_environments, validator: ARRAY_VALIDATOR
    config_accessor :include_for_logged_out_users
    config_accessor :hide_default_launcher
    config_accessor :api_base
    config_accessor :encrypted_mode

    # User configuration group
    class User < Config
      @underscored_class_name = :user

      config_accessor :current, validator: IS_PROC_OR_ARRAY_OF_PROC_VALIDATOR
      config_accessor :exclude_if, validator: IS_PROC_VALIDATOR
      config_accessor :model, validator: IS_PROC_VALIDATOR
      config_accessor :lead_attributes, validator: ARRAY_VALIDATOR
      config_accessor :custom_data, validator: CUSTOM_DATA_VALIDATOR

      def self.company_association=(*)
        warn "Setting a company association is no longer supported; remove the `config.user.company_association = ...` line from config/initializers/intercom.rb"
      end
    end

    # Company configuration group
    class Company < Config
      @underscored_class_name = :company

      config_accessor :current, validator: IS_PROC_VALIDATOR
      config_accessor :exclude_if, validator: IS_PROC_VALIDATOR
      config_accessor :plan, validator: IS_PROC_VALIDATOR
      config_accessor :monthly_spend, validator: IS_PROC_VALIDATOR
      config_accessor :custom_data, validator: CUSTOM_DATA_VALIDATOR
    end

    # Inbox configuration group
    class Inbox < Config
      @underscored_class_name = :inbox

      config_accessor :counter # Keep this for backwards compatibility
      config_accessor :custom_activator
      config_accessor :style, validator: Proc.new { |value|
        raise ArgumentError, "inbox.style must be one of :default or :custom" unless [:default, :custom].include?(value)
      }
    end

    # JWT configuration group
    class Jwt < Config
      @underscored_class_name = :jwt

      config_accessor :enabled
      config_accessor :expiry
      config_accessor :signed_user_fields, validator: Proc.new { |value|
        unless value.nil? || (value.kind_of?(Array) && value.all? { |v| v.kind_of?(Symbol) || v.kind_of?(String) })
          raise ArgumentError, "jwt.signed_user_fields must be an array of symbols or strings"
        end
      }
    end

    # Methods to access configuration groups
    def self.user
      User
    end

    def self.company
      Company
    end

    def self.inbox
      Inbox
    end

    def self.jwt
      Jwt
    end
  end

end
