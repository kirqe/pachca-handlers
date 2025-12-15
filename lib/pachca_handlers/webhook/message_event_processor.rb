# frozen_string_literal: true

require_relative 'event_processor'
require_relative '../flow/session_flow'
require_relative '../registry/handlers_registry'

module PachcaHandlers
  module Webhook
    class MessageEventProcessor < EventProcessor
      def process
        return handle_command(@event.command) if @event.command?

        # TODO: ref. key in session?
        session = @session_service.find_session
        return unless session

        handler_class = PachcaHandlers::Registry::HandlersRegistry.get(session.command)

        if handler_class.assistant?
          assistant_session_flow_class.new(
            event: @event,
            session_service: @session_service,
            message_service: @message_service
          ).continue

          return
        end

        @session_flow.continue
      end

      private

      def handle_command(command)
        case command
        when 'start'
          return handle_start_command
        when 'cancel', 'stop'
          return handle_cancel_command
        end

        handle_handler_command(command)
      end

      def handle_start_command
        commands = PachcaHandlers::Registry::HandlersRegistry.all
        buttons = commands.map do |_, klass|
          [{ text: klass.title, data: "cmd:#{klass.command}" }]
        end

        @message_service.deliver(I18n.t('messages.available_commands'), buttons)
      end

      def handle_cancel_command
        session = @session_service.find_session
        message = session&.cancel! ? I18n.t('messages.session_cancelled') : I18n.t('messages.session_not_found')

        @message_service.deliver(message)
      end
    end
  end
end
