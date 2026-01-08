# frozen_string_literal: true

require 'i18n'

require_relative '../../lib/pachca_handlers/flow/session_flow'
require_relative '../../lib/pachca_handlers/flow/steps_data_manager'
require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/registry/handlers_registry'

FileInputSession = Class.new do
  attr_accessor :steps_data
  attr_reader :command

  def initialize(command:)
    @command = command
    @steps_data = '{}'
    @completed = false
  end

  def save
    self
  end

  def complete!
    @completed = true
  end

  def completed?
    @completed
  end

  def steps_data_manager
    @steps_data_manager ||= PachcaHandlers::Flow::StepsDataManager.new(self)
  end
end

RSpec.describe 'File input fields' do
  before do
    PachcaHandlers::Registry::HandlersRegistry.instance_variable_set(:@handlers, {})
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(
      :en,
      { buttons: { back: 'Back' }, messages: { invalid_input: 'Invalid input' } }
    )
    I18n.default_locale = :en
  end

  it 'uses event files as field value when input is :file' do
    captured_value = nil

    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'file_test'

      step :upload do
        field :attachment do
          name 'File'
          input :file
          callback do |ctx|
            captured_value = ctx[:value]
            nil
          end
        end
      end
    end

    session = FileInputSession.new(command: 'file_test')
    session.steps_data_manager.prepare!

    event = instance_double(
      'Event',
      content: nil,
      params: {
        files: [
          { 'name' => 'users.csv', 'url' => 'https://example.test/users.csv', 'key' => 'k', 'file_type' => 'file' }
        ]
      }
    )
    session_service = instance_double('SessionService', find_session: session)
    message_service = instance_double('MessageService', deliver: true, post_result: true)

    PachcaHandlers::Flow::SessionFlow.new(
      event: event,
      session_service: session_service,
      message_service: message_service
    ).continue

    expect(captured_value).to include(name: 'users.csv', url: 'https://example.test/users.csv', key: 'k')
    expect(session).to be_completed
  end

  it 'rejects input without files when input is :file' do
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'file_test'

      step :upload do
        field :attachment do
          name 'File'
          input :file
        end
      end
    end

    session = FileInputSession.new(command: 'file_test')
    session.steps_data_manager.prepare!

    event = instance_double('Event', content: nil, params: { files: [] })
    session_service = instance_double('SessionService', find_session: session)
    message_service = instance_double('MessageService')

    expect(message_service).to receive(:deliver).with('Invalid input')

    PachcaHandlers::Flow::SessionFlow.new(
      event: event,
      session_service: session_service,
      message_service: message_service
    ).continue

    step, field = session.steps_data_manager.next_field
    expect([step.key, field.key]).to eq(%i[upload attachment])
    expect(session).not_to be_completed
  end

  it 'falls back to fetching message files when webhook has only id' do
    captured_value = nil

    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'file_test'

      step :upload do
        field :attachment do
          name 'File'
          input :file
          callback do |ctx|
            captured_value = ctx[:value]
            nil
          end
        end
      end
    end

    session = FileInputSession.new(command: 'file_test')
    session.steps_data_manager.prepare!

    event = instance_double('Event', content: nil, params: { id: 123 })
    session_service = instance_double('SessionService', find_session: session)
    message_service = instance_double(
      'MessageService',
      fetch_message: { 'files' => [{ 'name' => 'a.csv', 'url' => 'u' }] }
    )

    PachcaHandlers::Flow::SessionFlow.new(
      event: event,
      session_service: session_service,
      message_service: message_service
    ).continue

    expect(captured_value).to include(name: 'a.csv', url: 'u')
    expect(session).to be_completed
  end

  it 'rejects file input when message files have no url' do
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'file_test'

      step :upload do
        field :attachment do
          name 'File'
          input :file
        end
      end
    end

    session = FileInputSession.new(command: 'file_test')
    session.steps_data_manager.prepare!

    event = instance_double('Event', content: nil, params: { id: 123 })
    session_service = instance_double('SessionService', find_session: session)
    message_service_deliveries = []
    message_service_for_flow = double(
      'MessageService',
      fetch_message: { 'files' => [{ 'name' => 'a.csv' }] }
    )
    allow(message_service_for_flow).to receive(:deliver) { |msg| message_service_deliveries << msg }

    PachcaHandlers::Flow::SessionFlow.new(
      event: event,
      session_service: session_service,
      message_service: message_service_for_flow
    ).continue

    expect(message_service_deliveries.join("\n")).to include('Invalid input')
    expect(session).not_to be_completed
  end
end
