# frozen_string_literal: true

require_relative '../persistence/sequel_session_repo'

module PachcaHandlers
  module Flow
    class SessionService
      attr_reader :event

      def initialize(event, session_repo: PachcaHandlers::Persistence::SequelSessionRepo.new)
        @event = event
        @session_repo = session_repo
      end

      def find_or_create_session
        session = find_session
        return session if session

        @session_repo.create_active(
          user_id: @event.user_id,
          chat_id: @event.chat_id,
          entity_type: @event.entity_type,
          entity_id: @event.entity_id,
          command: @event.command
        )
      end

      def find_session
        @session_repo.find_active(
          user_id: @event.user_id,
          chat_id: @event.chat_id,
          entity_type: @event.entity_type,
          entity_id: @event.entity_id
        )
      end

      def cancel_existing_sessions
        @session_repo.cancel_active_for_user(user_id: @event.user_id, chat_id: @event.chat_id)
      end
    end
  end
end
