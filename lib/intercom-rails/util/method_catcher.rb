module IntercomRails
  module Util

    class MethodCatcher

      def initialize
        @method_names_called = []
      end
      
      def method_missing(method_name, *args, &block)
        @method_names_called << method_name
        nil 
      end

      def &(method_names)
        @method_names_called & method_names 
      end

    end

  end
end
