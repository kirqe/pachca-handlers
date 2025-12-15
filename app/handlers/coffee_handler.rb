# frozen_string_literal: true

require_relative '../../lib/internal/handlers/base_handler'

class CoffeeHandler < BaseHandler
  title 'Coffee Order'
  command 'coffee'

  step :choose_drink do
    intro 'Would you like Tea or Coffee?'
    field :drink do
      name 'Drink'
      description 'Choose your drink'
      options %w[Tea Coffee]
    end
  end

  step :extras do
    intro 'Would you like extras?'
    field :extra do
      name 'Extras'
      description 'Select an extra or go back'
      options %w[Sugar Milk]
      go_back_to :choose_drink
    end
  end

  step :name do
    intro 'What is your name?'
    field :customer_name do
      name 'Your name'
      description 'Enter your name for the order'
      validations [
        ->(value) { [!value.empty?, 'Name cannot be empty'] }
      ]
    end
  end

  step :summary do
    callback do |ctx|
      drink = ctx.get_field_value(:choose_drink, :drink)
      extra = ctx.get_field_value(:extras, :extra)
      name = ctx.get_field_value(:name, :customer_name)
      Result.success("Here's your drink: #{drink} with #{extra} for #{name}")
    end
  end
end
