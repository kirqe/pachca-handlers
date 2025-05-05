# frozen_string_literal: true

require_relative '../clients/pachca_client'
require_relative '../../services/session_service'
require_relative '../../services/message_service'
require_relative '../../services/session_flow'

class EventProcessorFactory
  def self.create(event)
    pachca_client = PachcaClient.new
    session_service = SessionService.new(event)
    message_service = MessageService.new(event, pachca_client)

    session_flow = SessionFlow.new(
      event: event,
      session_service: session_service,
      message_service: message_service
    )

    event.processor_class.new(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    )
  end
end
