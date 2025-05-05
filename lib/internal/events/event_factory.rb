# frozen_string_literal: true

require_relative 'event'
require_relative 'message_event'
require_relative 'button_event'

class EventFactory
  def self.create(params)
    case params['type']
    when 'message'
      MessageEvent.new(params)
    when 'button'
      ButtonEvent.new(params)
    else
      Event.new(params)
    end
  end
end
