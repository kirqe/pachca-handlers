# frozen_string_literal: true

require_relative '../internal/handlers/base_handler'

class EchoHandler < BaseHandler
  title 'Echo'
  command 'echo'

  step :echo do
    intro 'This is a sample handler that echoes back the message you send in the chat.'
    field :message do
      name 'Message'
      description 'The message to echo back'
      validations [
        ->(value) { [!value.empty?, 'Message cannot be empty'] },
        ->(value) { [value.length <= 3, 'Message cannot be longer than 3 characters'] }
      ]
      callback ->(ctx) { puts "Field callback with context #{ctx.inspect}" }
    end
    callback { puts 'Step callback' }
  end

  step :thanks do
    intro 'Thank you for using the Echo handler.'
    callback { puts 'Callback' }
  end

  def perform
    message = field_value(:echo, :message)
    Result.success("Echo: #{message}")
  end
end
