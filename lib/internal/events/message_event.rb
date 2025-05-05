# frozen_string_literal: true

require_relative 'event'
require_relative 'inline_params'
require_relative '../processors/message_event_processor'

class MessageEvent < Event
  def initialize(params)
    super
    @params[:inline_params] = InlineParams.new(params['content']).parse
  end

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

  def inline_params
    @params[:inline_params]
  end

  def processor_class
    MessageEventProcessor
  end
end
