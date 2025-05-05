# frozen_string_literal: true

require_relative '../internal/handlers/base_handler'

class MultiTestHandler < BaseHandler
  title 'Multi test'
  command 'm'

  step :welcome do
    intro '(Step 1)Multitest command intro: lorem ipsum dolor sit amet consectetur adipiscing '
    callback { puts 'Step callback 1. (Step 1)' }
  end

  step :multi_test do
    intro '(Step 2) Intro text for multipstep command. We see it because we provided `intro` key in a handler step'

    field :message1 do
      name 'Message 1 (step 2)'
      validations [
        ->(value) { [value.length >= 3, 'Message 1 must be longer than 3 characters'] }
      ]
      callback { puts 'Field callback 1. (Step 2)' }
    end

    field :message2 do
      name 'Message 2 (step 2)'
      validations [
        ->(value) { [value.length >= 3, 'Message 2 must be longer than 3 characters'] }
      ]
      callback { puts 'Field callback 2. (Step 2)' }
    end
    callback { puts 'Step callback 2. (Step 2)' }
  end

  step :thank_you do
    intro '(Step 3) Thank you, now one more field. This is a step without fields. Sort of notification step'
    callback { puts 'Step callback 3. (Step 3)' }
  end

  step :one_more_field do
    intro '(Step 4) One more field step that takes 1 field'

    field :message3 do
      name 'Message 3 (step 4)'
      validations [
        ->(value) { [value.length >= 3, 'Message 3 must be longer than 3 characters'] }
      ]
      callback { puts 'Field callback 1. (Step 4)' }
    end
    callback { puts 'Step callback 4. (Step 4)' }
  end

  def perform
    Result.success("Multi test #perform #{serialize_steps_data}")
  end
end
