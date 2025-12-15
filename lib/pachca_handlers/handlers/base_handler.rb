# frozen_string_literal: true

require_relative '../registry/handlers_registry'
require_relative '../result'
require_relative '../flow/step'

module PachcaHandlers
  module Handlers
    class BaseHandler
      attr_accessor :params, :session

      class << self
        def system_prompt(value = nil)
          return @system_prompt unless value

          @system_prompt = value
        end

        def system_prompt_i18n(value = nil)
          return @system_prompt_i18n unless value

          @system_prompt_i18n = value
        end

        def tools(*names)
          return @assistant_tools unless names.any?

          @assistant_tools = names.flatten
        end

        def assistant_model(value = nil)
          return @assistant_model unless value

          @assistant_model = value
        end

        def title(value = nil)
          return @title unless value

          @title = value
        end

        def command(value = nil)
          return @command unless value

          @command = value
          PachcaHandlers::Registry::HandlersRegistry.register(self, value)
        end

        def steps
          @steps ||= []
        end

        def no_steps?
          steps.empty?
        end

        def step(key, &block)
          step = PachcaHandlers::Flow::Step.new(key: key)
          step.instance_eval(&block) if block
          steps << step
        end

        def assistant(value = nil)
          return @assistant unless value

          @assistant = value
        end

        def assistant?
          !!@assistant
        end

        def system_prompt_text
          return I18n.t(system_prompt_i18n) if system_prompt_i18n
          return system_prompt.to_s if system_prompt

          I18n.t('instructions.assistant')
        end

        def tool_names
          if @assistant_tools.nil?
            return nil unless assistant?

            return ['CloseSession']
          end

          Array(@assistant_tools).map(&:to_s)
        end
      end

      def initialize(session: nil, params: {})
        @session = session
        @params = params
      end

      def perform
        nil
      end

      protected

      def field_value(step_key, field_key)
        session.steps_data_manager.field_value(step_key, field_key)
      end

      def serialize_steps_data
        session.steps_data_manager.serialize
      end
    end
  end
end
