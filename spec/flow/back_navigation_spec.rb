# frozen_string_literal: true

require 'i18n'
require 'json'

require_relative '../../lib/pachca_handlers/registry/handlers_registry'
require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/flow/steps_data_manager'
require_relative '../../lib/pachca_handlers/flow/button_navigator'
require_relative '../../lib/pachca_handlers/flow/callback_context'

FakeSession = Class.new do
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

RSpec.describe 'Back navigation' do
  before do
    PachcaHandlers::Registry::HandlersRegistry.instance_variable_set(:@handlers, {})
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, { buttons: { back: 'Back' } })
    I18n.default_locale = :en
  end

  it 'resets a field via StepsDataManager#reset_field!' do
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'test'

      step :one do
        field :name do
          name 'Name'
        end
      end
    end

    session = FakeSession.new(command: 'test')
    session.steps_data_manager.prepare!
    session.steps_data_manager.update_field!(:one, :name, 'Alice')
    session.steps_data_manager.update_step!(:one, :step_completed, true)

    session.steps_data_manager.reset_field!(:one, :name)

    field_obj = session.steps_data_manager.field(:one, :name)
    expect(field_obj[:visited]).to eq(false)
    expect(field_obj[:value]).to eq(nil)
    expect(session.steps_data_manager.step(:one)[:step_completed]).to eq(false)
  end

  it 'uses reset_field! from CallbackContext#go_back_to' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'test'

      step :one do
        field :name do
          name 'Name'
        end
      end
    end

    session = FakeSession.new(command: 'test')
    session.steps_data_manager.prepare!
    session.steps_data_manager.update_field!(:one, :name, 'Alice')

    handler = handler_class.new(session: session, params: {})
    ctx = PachcaHandlers::Flow::CallbackContext.new(handler: handler, step_key: :one)

    expect(ctx.go_back_to(:one, :name)).to eq(:restart)
    expect(session.steps_data_manager.field(:one, :name)[:visited]).to eq(false)
  end

  it 'uses reset_field! from ButtonNavigator#go_back_to' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'test'

      step :one do
        field :name do
          name 'Name'
        end
      end
    end

    session = FakeSession.new(command: 'test')
    session.steps_data_manager.prepare!
    session.steps_data_manager.update_field!(:one, :name, 'Alice')

    navigator = PachcaHandlers::Flow::ButtonNavigator.new(session: session, handler_class: handler_class,
                                                          message_service: nil)
    expect(navigator.go_back_to(:one, :name)).to eq(:restart)
    expect(session.steps_data_manager.field(:one, :name)[:visited]).to eq(false)
  end
end
