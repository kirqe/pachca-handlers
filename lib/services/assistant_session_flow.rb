# frozen_string_literal: true

require_relative '../services/assistant'

class AssistantSessionFlow
  def initialize(event:, session_service:, message_service:)
    @event = event
    @session_service = session_service
    @message_service = message_service
  end

  def continue
    return unless session

    session.initialize_chat_data!
    input = @event.content.strip

    if input.empty?
      @message_service.deliver(I18n.t('messages.assistant_welcome'))
      return
    end

    save_user_message(input)

    assistant = Assistant.new(chat_data_manager: session.chat_data_manager)
    result = assistant.ask(input, context: { session: session })

    save_assistant_message(result)

    @message_service.deliver(result)
  end

  private

  def session
    @session ||= @session_service.find_session
  end

  def save_user_message(text)
    session.chat_data_manager.add_message(role: 'user', content: text)
  end

  def save_assistant_message(text)
    session.chat_data_manager.add_message(role: 'assistant', content: text)
  end

  def complete_session(message)
    session.complete!
    @message_service.deliver(message)
  end
end
