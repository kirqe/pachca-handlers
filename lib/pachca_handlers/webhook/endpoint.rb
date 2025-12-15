# frozen_string_literal: true

require_relative 'event_factory'

module PachcaHandlers
  module Webhook
    class Endpoint
      def initialize(container: nil)
        @container = container || default_container
      end

      def call(params)
        event = PachcaHandlers::Webhook::EventFactory.create(params)
        @container.build_event_processor(event).process
      end

      private

      def default_container
        require_relative '../container'
        PachcaHandlers::Container.new
      end
    end
  end
end
