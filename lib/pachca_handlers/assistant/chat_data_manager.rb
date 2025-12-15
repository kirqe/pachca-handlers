# frozen_string_literal: true

require 'json'

module PachcaHandlers
  module Assistant
    class ChatDataManager
      def initialize(session)
        @session = session
        @chat_data = parse_chat_data
      end

      def parse_chat_data
        JSON.parse(@session.chat_data)
      rescue JSON::ParserError
        {}
      end

      def messages
        @chat_data['messages'] ||= []
      end

      def add_message(role:, content:)
        messages << { 'role' => role, 'content' => content }
        save!
      end

      def context
        @chat_data['context'] ||= {}
      end

      def update_context(new_context)
        @chat_data['context'] = context.merge(new_context)
        save!
      end

      def save!
        @session.chat_data = @chat_data.to_json
        @session.save
      end
    end
  end
end
