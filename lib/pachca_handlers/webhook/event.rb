# frozen_string_literal: true

module PachcaHandlers
  module Webhook
    class Event
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def type
        @params['type']
      end

      def command?
        false
      end

      def method_missing(method, *, &)
        method_str = method.to_s
        if @params.key?(method_str)
          @params[method_str]
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        method_str = method.to_s
        @params.key?(method_str) || super
      end

      def processor_class
        raise NotImplementedError, "#{self.class.name} must implement #processor_class"
      end
    end
  end
end
