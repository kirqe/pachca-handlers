# frozen_string_literal: true

require_relative 'event_factory'
require_relative 'event_processor_factory'

module PachcaHandlers
  module Webhook
    class Endpoint
      def call(params)
        event = EventFactory.create(params)
        EventProcessorFactory.create(event).process
      end
    end
  end
end
