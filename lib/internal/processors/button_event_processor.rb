# frozen_string_literal: true

require_relative 'event_processor'

class ButtonEventProcessor < EventProcessor
  def process
    handle_command(@event.command)
  end

  private

  def handle_command(command)
    handle_handler_command(command)
  end
end
