# frozen_string_literal: true

class MessageService
  def initialize(event, client)
    @event = event
    @client = client
  end

  def deliver(message, buttons = [])
    sleep 0.1
    @client.create_message({ message: {
                             entity_type: @event.entity_type,
                             entity_id: @event.entity_id,
                             content: message,
                             buttons: buttons
                           } })
  end

  def post_result(result)
    message = I18n.t('messages.command_failed', error: result.errors.join("\n"))

    if result.success?
      message = result.data
      message = I18n.t('messages.command_executed') if result.data.empty?
    end

    deliver(message)
  end
end
