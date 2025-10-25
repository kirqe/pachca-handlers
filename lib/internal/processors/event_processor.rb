# frozen_string_literal: true

require_relative '../handlers_registry'
require_relative '../../services/assistant_session_flow'

class EventProcessor
  def initialize(event:, session_service:, message_service:, session_flow:)
    @event = event
    @session_service = session_service
    @message_service = message_service
    @session_flow = session_flow
  end

  def process
    raise NotImplementedError
  end

  protected

  def handle_handler_command(command)
    @session_service.cancel_existing_sessions

    session = @session_service.find_or_create_session
    return unless session&.valid_user?(@event.user_id)

    handler_class = HandlersRegistry.get(command)
    return handle_unknown_command unless handler_class

    session.initialize_steps_data!

    handler = handler_class.new(session: session, params: @event.params)

    if handler_class.assistant?
      AssistantSessionFlow.new(
        event: @event,
        session_service: @session_service,
        message_service: @message_service
      ).continue

      return
    end

    if handler_class.no_steps?
      result = handler.perform
      @message_service.post_result(result) if result
      session.complete!
    else
      @session_flow.start
    end
  end

  def handle_unknown_command
    @message_service.deliver(I18n.t('messages.command_not_found'))
  end
end
