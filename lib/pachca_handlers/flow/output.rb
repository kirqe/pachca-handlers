# frozen_string_literal: true

require_relative '../result'

module PachcaHandlers
  module Flow
    class Output
      attr_reader :messages

      def initialize(messages: [], restart: false)
        @messages = messages
        @restart = restart
      end

      def restart?
        !!@restart
      end

      def empty?
        @messages.empty? && !restart?
      end

      def self.none
        new(messages: [], restart: false)
      end

      def self.restart
        new(messages: [], restart: true)
      end

      def self.from(value)
        case value
        when nil
          none
        when Output
          value
        when Symbol
          return restart if value == :restart

          raise TypeError, "Unsupported callback output symbol: #{value.inspect}"
        when Array
          combine(value.map { |v| from(v) })
        when PachcaHandlers::Result, String
          new(messages: [value], restart: false)
        else
          raise TypeError, "Unsupported callback output: #{value.class}"
        end
      end

      def self.combine(outputs)
        outputs = outputs.compact
        messages = outputs.flat_map(&:messages)
        restart = outputs.any?(&:restart?)
        new(messages: messages, restart: restart)
      end
    end
  end
end
