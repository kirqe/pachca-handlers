# frozen_string_literal: true

module PachcaHandlers
  module Flow
    class CallbackContext
      def initialize(context)
        @params = context[:params]
        @handler = context[:handler]
        @step = context[:step]
        @value = context[:value]
        @step_key = context[:step_key]
        @field_key = context[:field_key]
      end

      def [](key)
        case key
        when :params then @params
        when :handler then @handler
        when :step then @step
        when :value then @value
        when :step_key then @step_key
        when :field_key then @field_key
        end
      end

      def go_back_to(step_key, field_key = nil)
        @handler.session.steps_data_manager.go_back_to(step_key, field_key)
      end

      def set_field(field_key, value)
        @handler.session.steps_data_manager.update_field!(@step_key, field_key, value)
        nil
      end

      def get_field_value(step_key, field_key)
        @handler.session.steps_data_manager.field_value(step_key, field_key)
      end

      def skip_step(step_key = @step_key)
        @handler.session.steps_data_manager.update_step!(step_key, :skipped, true)
        nil
      end

      def unskip_step(step_key = @step_key)
        @handler.session.steps_data_manager.update_step!(step_key, :skipped, false)
        nil
      end

      def reset_field(step_key, field_key)
        @handler.session.steps_data_manager.reset_field!(step_key, field_key)
        nil
      end

      def complete_step
        @handler.session.steps_data_manager.update_step!(@step_key, :step_completed, true)
        nil
      end
    end
  end
end
