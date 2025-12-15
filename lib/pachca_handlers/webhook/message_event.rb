# frozen_string_literal: true

require_relative 'event'

module PachcaHandlers
  module Webhook
    class MessageEvent < Event
      def content
        @params['content']
      end

      def command
        return unless content&.start_with?('/')

        content.split[0].sub('/', '')
      end

      def command?
        !!command
      end

      def processor_class
        PachcaHandlers::Webhook::MessageEventProcessor
      end
    end
  end
end
