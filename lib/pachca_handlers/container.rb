# frozen_string_literal: true

require_relative 'integrations/pachca_client'
require_relative 'persistence/sequel_session_repo'

module PachcaHandlers
  class Container
    def initialize(
      pachca_client: nil,
      session_repo: nil,
      session_service_class: nil,
      message_service_class: nil,
      session_flow_class: nil
    )
      @pachca_client = pachca_client || PachcaHandlers::Integrations::PachcaClient.new
      @session_repo = session_repo
      @session_service_class = session_service_class
      @message_service_class = message_service_class
      @session_flow_class = session_flow_class
    end

    def build_event_processor(event)
      session_service_class = @session_service_class || PachcaHandlers::Flow::SessionService
      message_service_class = @message_service_class || PachcaHandlers::Flow::MessageService
      session_flow_class = @session_flow_class || PachcaHandlers::Flow::SessionFlow

      session_service =
        if @session_repo
          session_service_class.new(event, session_repo: @session_repo)
        else
          session_service_class.new(event)
        end
      message_service = message_service_class.new(event, @pachca_client)
      session_flow = session_flow_class.new(
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
end
