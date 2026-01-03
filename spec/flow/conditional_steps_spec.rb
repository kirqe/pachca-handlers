# frozen_string_literal: true

require 'i18n'

require_relative '../../lib/pachca_handlers/registry/handlers_registry'
require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/flow/steps_data_manager'

ConditionalStepsSession = Class.new do
  attr_accessor :steps_data
  attr_reader :command

  def initialize(command:)
    @command = command
    @steps_data = '{}'
  end

  def save
    self
  end

  def steps_data_manager
    @steps_data_manager ||= PachcaHandlers::Flow::StepsDataManager.new(self)
  end
end
RSpec.describe 'Conditional steps' do
  before do
    PachcaHandlers::Registry::HandlersRegistry.instance_variable_set(:@handlers, {})
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, { buttons: { back: 'Back' } })
    I18n.default_locale = :en
  end

  it 'skips a step when skip_if is true' do
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'test'

      step :choose_drink do
        field :drink do
          name 'Drink'
          options %w[Tea Coffee]
        end
      end

      step :extras do
        skip_if do |ctx|
          ctx.get_field_value(:choose_drink, :drink) == 'Tea'
        end

        field :extra do
          name 'Extra'
          options %w[Sugar Milk]
        end
      end

      step :name do
        field :customer_name do
          name 'Name'
        end
      end
    end

    session = ConditionalStepsSession.new(command: 'test')
    session.steps_data_manager.prepare!

    step, field = session.steps_data_manager.next_field
    expect([step.key, field.key]).to eq(%i[choose_drink drink])

    session.steps_data_manager.update_field!(:choose_drink, :drink, 'Tea')
    step, field = session.steps_data_manager.next_field
    expect([step.key, field.key]).to eq(%i[name customer_name])

    session.steps_data_manager.update_field!(:choose_drink, :drink, 'Coffee')
    step, field = session.steps_data_manager.next_field
    expect([step.key, field.key]).to eq(%i[extras extra])
  end

  it 'skips a step when ctx.skip_step is called' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'test'

      step :one do
        field :a do
          name 'A'
        end
      end

      step :two do
        field :b do
          name 'B'
        end
      end

      step :three do
        field :c do
          name 'C'
        end
      end
    end

    session = ConditionalStepsSession.new(command: 'test')
    session.steps_data_manager.prepare!

    handler = handler_class.new(session: session, params: {})
    ctx = PachcaHandlers::Flow::CallbackContext.new(handler: handler, step_key: :one)

    session.steps_data_manager.update_field!(:one, :a, 'x')
    ctx.skip_step(:two)

    step, field = session.steps_data_manager.next_field
    expect([step.key, field.key]).to eq(%i[three c])
  end
end
