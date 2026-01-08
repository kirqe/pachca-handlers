# frozen_string_literal: true

require_relative 'event_processor'
require_relative '../flow/button_navigator'

module PachcaHandlers
  module Webhook
    class ButtonEventProcessor < EventProcessor
      def process!
        return handle_handler_command(@event.command) if @event.command?

        handle_field_click if @event.field?
      end

      private

      def handle_field_click
        session = @session_service.find_session
        return unless session
        return unless session.valid_user?(@event.user_id)

        payload = @event.field_payload
        return unless payload
        return unless session.command == payload[:command]

        handler_class = PachcaHandlers::Registry::HandlersRegistry.get(session.command)
        navigator = PachcaHandlers::Flow::ButtonNavigator.new(
          session: session,
          handler_class: handler_class,
          message_service: @message_service
        )

        out = navigator.handle_field_click(
          step_key: payload[:step_key],
          field_key: payload[:field_key],
          value: payload[:value],
          event_params: @event.params
        )

        @session_flow.handle_button_result(out: out, step_key: payload[:step_key])
      end
    end
  end
end
