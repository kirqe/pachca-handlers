# frozen_string_literal: true

require_relative 'event'
require 'cgi'

module PachcaHandlers
  module Webhook
    class ButtonEvent < Event
      def data
        @params['data']
      end

      def verb
        data.split(':')[0]
      end

      def field?
        verb == 'field'
      end

      def command?
        verb == 'cmd'
      end

      def command
        return unless command?

        data.split(':')[1]
      end

      def field_payload
        return unless field?

        verb, command, step_key, field_key, value = data.split(':', 5)
        return unless verb == 'field' && command && step_key && field_key

        {
          command: command,
          step_key: step_key.to_sym,
          field_key: field_key.to_sym,
          value: CGI.unescape(value.to_s)
        }
      end

      def entity_type
        @params['entity_type'] || 'discussion'
      end

      def entity_id
        @params['entity_id'] || @params['chat_id']
      end

      def chat_id
        @params['chat_id']
      end

      def content
        ''
      end

      def processor_class
        PachcaHandlers::Webhook::ButtonEventProcessor
      end
    end
  end
end
