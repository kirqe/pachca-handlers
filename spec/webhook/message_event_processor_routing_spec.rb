# frozen_string_literal: true

require 'i18n'
require_relative '../spec_helper'

require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/registry/handlers_registry'
require_relative '../../lib/pachca_handlers/result'
require_relative '../../lib/pachca_handlers/webhook/message_event_processor'

RSpec.describe PachcaHandlers::Webhook::MessageEventProcessor do
  before do
    PachcaHandlers::Registry::HandlersRegistry.instance_variable_set(:@handlers, {})

    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(
      :en,
      messages: {
        available_commands: 'Available commands',
        command_not_found: 'Command not found',
        session_cancelled: 'Cancelled',
        session_not_found: 'No session'
      }
    )
    I18n.default_locale = :en
  end

  def build_processor(event:, session_service:, message_service:, session_flow:)
    described_class.new(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    )
  end

  it 'handles /start by listing commands as buttons' do
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title('Echo')
      command('echo')
    end
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title('Coffee')
      command('coffee')
    end

    event = double('Event', command?: true, command: 'start')
    session_service = double('SessionService')
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(message_service).to receive(:deliver) do |message, buttons|
      expect(message).to eq('Available commands')
      flat = buttons.flatten
      expect(flat.map { |b| b[:text] }).to match_array(%w[Echo Coffee])
      expect(flat.map { |b| b[:data] }).to match_array(%w[cmd:echo cmd:coffee])
    end

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'handles /cancel when a session exists' do
    event = double('Event', command?: true, command: 'cancel')
    session = double('Session', cancel!: true)
    session_service = double('SessionService', find_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(message_service).to receive(:deliver).with('Cancelled')

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'handles /cancel when no session exists' do
    event = double('Event', command?: true, command: 'cancel')
    session_service = double('SessionService', find_session: nil)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(message_service).to receive(:deliver).with('No session')

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'delivers command_not_found for unknown commands' do
    event = double('Event', command?: true, command: 'nope', user_id: 1, params: {})
    session = double('Session', valid_user?: true)
    session_service = double('SessionService', cancel_existing_sessions: true, find_or_create_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(message_service).to receive(:deliver).with('Command not found')

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'runs a no-steps handler via perform and completes the session' do
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'NoSteps'
      command 'nosteps'

      def perform
        PachcaHandlers::Result.success('ok')
      end
    end

    event = double('Event', command?: true, command: 'nosteps', user_id: 1, params: {})
    session = double('Session',
                     valid_user?: true,
                     initialize_steps_data!: true,
                     complete!: true)
    session_service = double('SessionService', cancel_existing_sessions: true, find_or_create_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(message_service).to receive(:post_result) do |result|
      expect(result).to be_a(PachcaHandlers::Result)
      expect(result.to_s).to eq('ok')
    end
    expect(session_flow).not_to receive(:start)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'starts SessionFlow for a handler with steps' do
    Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Stepped'
      command 'stepped'

      step :one do
        field :message do
          name 'Message'
        end
      end
    end

    event = double('Event', command?: true, command: 'stepped', user_id: 1, params: {})
    session = double('Session',
                     valid_user?: true,
                     initialize_steps_data!: true)
    session_service = double('SessionService', cancel_existing_sessions: true, find_or_create_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(session_flow).to receive(:start)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'continues the active session when the message is not a command' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Stepped'
      command 'stepped'

      step :one do
        field :message do
          name 'Message'
        end
      end
    end

    event = double('Event', command?: false)
    session = double('Session', command: handler_class.command)
    session_service = double('SessionService', find_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(session_flow).to receive(:continue)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end
end
