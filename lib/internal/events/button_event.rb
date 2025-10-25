# frozen_string_literal: true

require_relative 'event'
require_relative '../processors/button_event_processor'

class ButtonEvent < Event
  def data
    @params['data']
  end

  def verb
    data.split(':')[0]
  end

  def command?
    verb == 'cmd'
  end

  def command
    return unless command?

    data.split(':')[1]
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
    ButtonEventProcessor
  end
end
