class Module

  def config_accessor(*args, &block)
    config_reader(*args)
    config_writer(*args, &block)
  end

  def config_reader(name)
    self.send(:define_singleton_method, name) do
      instance_variable_get("@#{name}")
    end
  end

  def config_writer(name, &block)
    self.send(:define_singleton_method, "#{name}=") do |value|
      block.call(value) if block
      instance_variable_set("@#{name}", value)
    end
  end

  def config_group(name, &block)
    camelized_name = name.to_s.split('_').map { |s| s[0].upcase + s[1..-1] }.join('')
    group = self.const_set(camelized_name, Module.new)

    self.send(:define_singleton_method, name) do
      group
    end

    group.instance_eval(&block)
  end

end

module IntercomRails

  module Config

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
    config_accessor :api_secret
    config_accessor :api_key
    config_accessor :library_url

    config_group :user do
      config_accessor :current do |value|
        raise ArgumentError, "user.current should be a Proc" unless value.kind_of?(Proc)
      end

      config_accessor :model do |value|
        raise ArgumentError, "user.model should be a Proc" unless value.kind_of?(Proc)
      end

      config_accessor :company_association do |value|
        raise ArgumentError, "company_association should be a Proc" unless value.kind_of?(Proc)
      end

      config_accessor :custom_data do |value|
        raise ArgumentError, "user.custom_data should be a hash" unless value.kind_of?(Hash)
        unless value.reject { |_,v| v.kind_of?(Proc) || v.kind_of?(Symbol) }.count.zero?
          raise ArgumentError, "all custom_data attributes should be either a Proc or a symbol"
        end
      end
    end
    
    config_group :company do
      config_accessor :current do |value|
        raise ArgumentError, "company.current should be a Proc" unless value.kind_of?(Proc)
      end

      config_accessor :custom_data do |value|
        raise ArgumentError, "company.custom_data should be a hash" unless value.kind_of?(Hash)
        unless value.reject { |_,v| v.kind_of?(Proc) || v.kind_of?(Symbol) }.count.zero?
          raise ArgumentError, "all custom_data attributes should be either a Proc or a symbol"
        end
      end
    end

    config_group :inbox do
      config_accessor :counter

      config_accessor :style do |value|
        raise ArgumentError, "inbox.style must be one of :default or :custom" unless [:default, :custom].include?(value)
      end
    end

  end

end
