# frozen_string_literal: true

require_relative 'assistant'
require_relative '../registry/handlers_registry'

module PachcaHandlers
  module Assistant
    class AssistantSessionFlow
      def initialize(event:, session_service:, message_service:)
        @event = event
        @session_service = session_service
        @message_service = message_service
      end

      def continue
        return unless session

        handler_class = PachcaHandlers::Registry::HandlersRegistry.get(session.command)
        raise KeyError, "Unknown handler for assistant session: #{session.command.inspect}" unless handler_class

        input = normalized_input.to_s.strip

        session.initialize_chat_data!(system_prompt: handler_class.system_prompt_text)
        input = input.to_s.strip

        if input.empty?
          @message_service.deliver(I18n.t('messages.assistant_welcome'))
          return
        end

        assistant = Assistant.new(
          chat_data_manager: session.chat_data_manager,
          tool_names: handler_class.tool_names,
          model: handler_class.assistant_model
        )
        result = assistant.ask(input, context: { session: session })

        @message_service.deliver(result)
      end

      private

      def session
        @session ||= @session_service.find_session
      end

      def normalized_input
        raw = @event.content.to_s.strip

        if command_invocation?
          tokens = raw.split
          tokens.shift # "/#{session.command}"
          raw = tokens.join(' ')
        end

        raw
      end

      def command_invocation?
        return false unless @event.respond_to?(:command?) && @event.command?
        return false unless @event.respond_to?(:command)

        @event.command.to_s == session.command.to_s
      end
    end
  end
end
