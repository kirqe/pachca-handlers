# frozen_string_literal: true

require_relative '../registry/handlers_registry'
require_relative 'output'
require_relative 'field_prompter'
require_relative 'input_value_extractor'

module PachcaHandlers
  module Flow
    class SessionFlow
      def initialize(event:, session_service:, message_service:)
        @event = event
        @session_service = session_service
        @message_service = message_service
      end

      def start
        advance(mode: :prompt)
      end

      def show_intro_if_needed(step)
        return unless step.show_intro? && !intro_shown?(step)

        existing_prompt_id = session.steps_data_manager.last_prompt_message_id
        show_intro(step) unless existing_prompt_id
      end

      def continue
        advance(mode: :input)
      end

      def handle_field_input(step, field)
        value = input_extractor.value_for(field)
        error = input_extractor.missing_input_error(field, value)
        return deliver_invalid_input(error) if error

        field.validate(value)
        return deliver_validation_error(field) unless field.valid?

        handle_valid_input(step: step, field: field, value: value)
      end

      def deliver_invalid_input(error)
        @message_service.deliver(I18n.t('messages.invalid_input', error: error.to_s))
      end

      def deliver_validation_error(field)
        @message_service.deliver(I18n.t('messages.invalid_input', error: field.errors.join(', ')))
      end

      def handle_valid_input(step:, field:, value:)
        output = fill_field(step, field, value)
        return if output&.restart?

        if step.complete?(session)
          output = complete_step(step)
          return if output&.restart?
        end

        advance(mode: :prompt)
      end

      def complete_step(step)
        session.steps_data_manager.update_step!(step.key, :step_completed, true)
        out = step.evaluated_field(:callback, { params: @event.params,
                                                handler: handler,
                                                step: step,
                                                message_service: @message_service })
        deliver_callback_output(out)
      end

      def deliver_callback_output(out)
        output = PachcaHandlers::Flow::Output.from(out)
        return output if output.empty?

        output.messages.each do |message|
          case message
          when PachcaHandlers::Result
            @message_service.post_result(message)
          when String
            @message_service.deliver(message)
          else
            raise TypeError, "Unexpected normalized output: #{message.class}"
          end

          session.steps_data_manager.mark_emitted_output!
        end

        return output unless output.restart?

        session.steps_data_manager.mark_emitted_output!
        start

        output
      end

      def handle_button_result(out:, step_key:)
        return start if out == :restart

        deliver_callback_output(out) if out

        output = complete_step_if_needed(step_key)
        return if output&.restart?

        start
      end

      private

      def session
        @session ||= @session_service.find_session
      end

      def advance(mode:)
        return unless session

        loop do
          result = advance_once(mode: mode)
          return if result != :continue
        end
      end

      def advance_once(mode:)
        target = next_target
        return target if target == :restart

        return complete_session unless target

        step, field = target
        show_intro_if_needed(step)

        return :continue if handle_non_field_target?(step: step, field: field)

        if mode == :prompt
          prompter.prompt(step: step, field: field)
        else
          handle_field_input(step, field)
        end
      end

      def handle_non_field_target?(step:, field:)
        return false unless step.fields.empty? || field.nil?

        output = complete_step(step)
        return true unless output&.restart?

        true
      end

      def handle_no_more_fields
        handler_class = PachcaHandlers::Registry::HandlersRegistry.get(session.command)
        handler_class.steps.each do |step|
          next if session.steps_data_manager.skip_step?(step)

          step_obj = session.steps_data_manager.step(step.key)
          next if step_obj[:step_completed] || step_obj[:skipped]
          next unless step.fields.empty?

          output = complete_step(step)
          return :restart if output&.restart?
        end
        nil
      end

      def next_target
        result = session.steps_data_manager.next_field
        return result if result

        return :restart if handle_no_more_fields == :restart

        nil
      end

      def show_intro(step)
        intro = step.evaluated_field(:intro, { params: @event.params,
                                               handler: handler,
                                               step: step,
                                               message_service: @message_service })
        @message_service.deliver(I18n.t('messages.step_intro', message: intro))
        session.steps_data_manager.update_step!(step.key, :intro_shown, true)
      end

      def intro_shown?(step)
        step_obj = session.steps_data_manager.step(step.key)
        step_obj[:intro_shown]
      end

      def fill_field(step, field, value)
        session.steps_data_manager.update_field!(step.key, field.key, value)
        out = field.evaluated_field(:callback, { params: @event.params,
                                                 handler: handler,
                                                 step: step,
                                                 value: value,
                                                 step_key: step.key,
                                                 field_key: field.key,
                                                 message_service: @message_service })
        deliver_callback_output(out)
      end

      def complete_step_if_needed(step_key)
        handler_class = PachcaHandlers::Registry::HandlersRegistry.get(session.command)
        current_step = handler_class.steps.find { |s| s.key.to_sym == step_key.to_sym }
        return unless current_step&.complete?(session)

        complete_step(current_step)
      end

      def complete_session
        unless session.steps_data_manager.emitted_output?
          result = handler.perform
          @message_service.post_result(result) if result
        end
        session.complete!
      end

      def handler
        @handler ||= session.steps_data_manager.handler_class.new(session: session, params: @event.params)
      end

      def prompter
        @prompter ||= PachcaHandlers::Flow::FieldPrompter.new(session: session, message_service: @message_service)
      end

      def input_extractor
        @input_extractor ||= PachcaHandlers::Flow::InputValueExtractor.new(
          event: @event,
          message_service: @message_service
        )
      end
    end
  end
end
