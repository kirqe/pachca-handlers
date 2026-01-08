# frozen_string_literal: true

require_relative 'evaluated_field'

module PachcaHandlers
  module Flow
    class Field
      include EvaluatedField

      attr_reader :key, :errors

      def initialize(key:)
        @key = key
        @validations = []
        @errors = []
        @input_type = :text
      end

      def name(value = nil)
        return @name unless value

        @name = value
      end

      def description(value = nil)
        return @description unless value

        @description = value
      end

      # :text (default), :file (single attachment), :files (multiple attachments)
      def input(value = nil)
        return @input_type unless value

        @input_type = value.to_sym
      end

      def validations(value = nil)
        return @validations unless value

        @validations = value
      end

      # options to pick from instead of text input
      def options(value = nil)
        return effective_options unless value

        @options = value
      end

      def callback(proc = nil, &block)
        return @callback unless proc || block_given?

        @callback = proc || block
      end

      def go_back_to(step_key)
        @go_back_to = step_key
      end

      def go_back_target
        @go_back_to
      end

      def validate(value)
        @errors = []

        @validations.each do |validation|
          result = validation.call(value)
          if result.is_a?(Array)
            valid, message = result
            @errors << message unless valid
          else
            @errors << 'Failed to validate' unless result
          end
        end

        @errors
      end

      def add_validation(validation)
        @validations << validation
        self
      end

      def valid?
        @errors.empty?
      end

      private

      # auto-inject back button when go_back_to is defined
      def effective_options
        return @options unless @go_back_to

        (@options || []) + [I18n.t('buttons.back')]
      end
    end
  end
end
