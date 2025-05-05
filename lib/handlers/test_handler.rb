# frozen_string_literal: true

require_relative '../internal/handlers/base_handler'

class TestHandler < BaseHandler
  title 'Inline params handler'
  command 'test'

  step :test do
    intro lambda { |ctx|
      "This is a test step #{ctx[:params][:inline_params][:message]}"
    }
    callback ->(ctx) { puts "Step callback with context #{ctx.inspect}" }
  end

  step :test2 do
    intro 'No context'
  end

  def perform
    inline_params = params[:inline_params]

    if inline_params
      Result.success("Other handler #perform. Inline params #{inline_params.inspect}")
    else
      Result.error(['Sample error - no inline params provided', 'Another error', 'And another one'])
    end
  end
end
