# frozen_string_literal: true

module PachcaHandlers
  module Persistence
    class SequelSessionRepo
      def initialize(session_model: nil)
        @session_model = session_model
      end

      def find_active(user_id:, chat_id:, entity_type:, entity_id:)
        session_model.find(
          user_id: user_id,
          chat_id: chat_id,
          entity_type: entity_type,
          entity_id: entity_id,
          status: session_model::STATUSES[:active]
        )
      end

      def create_active(user_id:, chat_id:, entity_type:, entity_id:, command:)
        session_model.create(
          user_id: user_id,
          chat_id: chat_id,
          entity_type: entity_type,
          entity_id: entity_id,
          command: command,
          status: session_model::STATUSES[:active]
        )
      end

      def cancel_active_for_user(user_id:, chat_id:)
        session_model
          .where(user_id: user_id, chat_id: chat_id, status: session_model::STATUSES[:active])
          .update(status: session_model::STATUSES[:finished])
      end

      private

      def session_model
        return @session_model if @session_model

        require_relative '../../../models/session'
        @session_model = ::Session
      end
    end
  end
end
