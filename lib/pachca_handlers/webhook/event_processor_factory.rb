# frozen_string_literal: true

require_relative '../container'

module PachcaHandlers
  module Webhook
    class EventProcessorFactory
      def self.create(event)
        PachcaHandlers::Container.new.build_event_processor(event)
      end
    end
  end
end
