# frozen_string_literal: true

require 'cgi'
require_relative 'event_processor'
require_relative '../flow/button_navigator'

module PachcaHandlers
  module Webhook
    class ButtonEventProcessor < EventProcessor
      def process
        data = @event.data
        verb = data.split(':')[0]
        if verb == 'field'
          handle_field_click
        else
          handle_command(@event.command)
        end
      end

      private

      def handle_command(command)
        handle_handler_command(command)
      end

      def handle_field_click
        session = find_valid_session
        return unless session

        navigator = create_navigator(session)
        payload = parse_and_validate_payload(navigator)
        return unless payload

        step_key, field_key, value = payload
        out = navigator.handle_field_click(step_key: step_key, field_key: field_key, value: value,
                                           event_params: @event.params)

        handle_field_click_result(out, session, step_key)
      end

      def find_valid_session
        session = @session_service.find_session
        return unless session
        return unless session.valid_user?(@event.user_id)

        session
      end

      def create_navigator(session)
        PachcaHandlers::Flow::ButtonNavigator.new(session: session,
                                                  handler_class: PachcaHandlers::Registry::HandlersRegistry.get(session.command),
                                                  message_service: @message_service)
      end

      def parse_and_validate_payload(navigator)
        verb, command, step_key, field_key, value = navigator.parse_payload(@event.data)
        return unless verb == 'field'
        return unless @session_service.find_session&.command == command

        [step_key, field_key, value]
      end

      def handle_field_click_result(out, session, step_key)
        if out == :restart
          @session_flow.start
        else
          deliver_and_continue(out, session, step_key)
        end
      end

      def deliver_and_continue(out, session, step_key)
        @session_flow.deliver_callback_output(out) if out
        check_and_complete_step(session, step_key)
        @session_flow.start
      end

      def check_and_complete_step(session, step_key)
        handler_class = PachcaHandlers::Registry::HandlersRegistry.get(session.command)
        current_step = handler_class.steps.find { |s| s.key.to_sym == step_key }
        return unless current_step&.complete?(session)

        @session_flow.complete_step(current_step)
      end
    end
  end
end
