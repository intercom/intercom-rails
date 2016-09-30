require 'active_support/inflector'

module IntercomRails

  class ConfigSingleton

    def self.config_accessor(*args, &block)
      config_reader(*args)
      config_writer(*args, &block)
    end

    def self.meta_class
      class << self; self end
    end

    def self.config_reader(name)
      meta_class.send(:define_method, name) do
        instance_variable_get("@#{name}")
      end
    end

    def self.config_writer(name, &block)
      meta_class.send(:define_method, "#{name}=") do |value|
        validate(name, value, block)
        instance_variable_set("@#{name}", value)
      end
    end

    def self.config_group(name, &block)
      camelized_name = name.to_s.classify
      group = self.const_set(camelized_name, Class.new(self))

      meta_class.send(:define_method, name) do
        group
      end

      group.send(:instance_variable_set, :@underscored_class_name, name)
      group.instance_eval(&block)
    end

    private

    def self.validate(name, value, block)
      return unless block
      args = [value]
      if block.arity > 1
        field_name = underscored_class_name ? "#{underscored_class_name}.#{name}" : name
        args << field_name
      end
      block.call(*args)
    end

    def self.underscored_class_name
      @underscored_class_name
    end

  end

  class Config < ConfigSingleton

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

    def self.reset!
      to_reset = self.constants.map {|c| const_get c}
      to_reset << self

      to_reset.each do |configer|
        configer.instance_variables.each do |var|
          configer.send(:remove_instance_variable, var)
        end
      end
    end

    config_accessor :app_id
    config_accessor :session_duration
    config_accessor :api_secret
    config_accessor :library_url
    config_accessor :enabled_environments, &ARRAY_VALIDATOR
    config_accessor :include_for_logged_out_users
    config_accessor :hide_default_launcher

    def self.api_key=(*)
      warn "Setting an Intercom API key is no longer supported; remove the `config.api_key = ...` line from config/initializers/intercom.rb"
    end

    config_group :user do
      config_accessor :current, &IS_PROC_OR_ARRAY_OF_PROC_VALIDATOR
      config_accessor :exclude_if, &IS_PROC_VALIDATOR
      config_accessor :model, &IS_PROC_VALIDATOR
      config_accessor :lead_attributes, &ARRAY_VALIDATOR
      config_accessor :custom_data, &CUSTOM_DATA_VALIDATOR

      def self.company_association=(*)
        warn "Setting a company association is no longer supported; remove the `config.user.company_association = ...` line from config/initializers/intercom.rb"
      end
    end

    config_group :company do
      config_accessor :current, &IS_PROC_VALIDATOR
      config_accessor :exclude_if, &IS_PROC_VALIDATOR
      config_accessor :plan, &IS_PROC_VALIDATOR
      config_accessor :monthly_spend, &IS_PROC_VALIDATOR
      config_accessor :custom_data, &CUSTOM_DATA_VALIDATOR
    end

    config_group :inbox do
      config_accessor :counter # Keep this for backwards compatibility
      config_accessor :custom_activator
      config_accessor :style do |value|
        raise ArgumentError, "inbox.style must be one of :default or :custom" unless [:default, :custom].include?(value)
      end
    end

  end

end
