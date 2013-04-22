module IntercomRails
  module Util
    class MethodCatcher

      attr_reader :methods_called
      def initialize
        @methods_called = []
      end

      def method_missing(method_name, *args, &block)
        @methods_called << method_name
        nil
      end

      def &(methods)
        @methods_called & methods
      end

    end
  end
end
