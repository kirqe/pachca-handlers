# frozen_string_literal: true

require_relative 'event'
require_relative '../processors/button_event_processor'

class ButtonEvent < Event
  def data
    @params['data']
  end

  def command?
    data.split(':')[0] == 'cmd'
  end

  def command
    data.split(':')[1]
  end

  def entity_type
    data.split(':')[2]
  end

  def entity_id
    data.split(':')[3]
  end

  def processor_class
    ButtonEventProcessor
  end
end
