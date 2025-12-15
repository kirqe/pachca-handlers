# frozen_string_literal: true

module PachcaHandlers
  module Flow
    class MessageService
      def initialize(event, client)
        @event = event
        @client = client
      end

      def deliver(message, buttons = [])
        sleep 0.1
        payload = build_message_payload(message, buttons)
        @client.create_message(payload)
      end

      def deliver_with_id(message, buttons = [])
        sleep 0.1
        payload = build_message_payload(message, buttons)
        response = @client.create_message(payload)
        response.body.dig('data', 'id')
      end

      def update_message(message_id, content: nil, buttons: [])
        sleep 0.1
        body = { message: {} }
        body[:message][:content] = content unless content.nil?
        body[:message][:buttons] = buttons unless buttons.nil?
        @client.update_message(message_id, body)
      end

      def post_result(result)
        message = I18n.t('messages.command_failed', error: result.errors.join("\n"))

        if result.success?
          message = result.data
          message = I18n.t('messages.command_executed') if result.data.empty?
        end

        deliver(message)
      end

      private

      def build_message_payload(message, buttons)
        { message: {
          entity_type: @event.entity_type,
          entity_id: @event.entity_id,
          content: message,
          buttons: buttons
        } }
      end
    end
  end
end
