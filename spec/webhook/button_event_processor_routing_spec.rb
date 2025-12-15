# frozen_string_literal: true

require 'i18n'
require_relative '../spec_helper'

require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/registry/handlers_registry'
require_relative '../../lib/pachca_handlers/webhook/button_event_processor'

RSpec.describe PachcaHandlers::Webhook::ButtonEventProcessor do
  before do
    PachcaHandlers::Registry::HandlersRegistry.instance_variable_set(:@handlers, {})

    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(
      :en,
      buttons: { back: 'Back' }
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

  it 'ignores field click when no active session' do
    event = double('Event', data: 'field:echo:one:message:Hi', params: {}, user_id: 1)
    session_service = double('SessionService', find_session: nil)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(session_flow).not_to receive(:start)
    expect(session_flow).not_to receive(:deliver_callback_output)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'ignores field click when session user mismatch' do
    session = double('Session', valid_user?: false)
    event = double('Event', data: 'field:echo:one:message:Hi', params: {}, user_id: 1)
    session_service = double('SessionService', find_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(session_flow).not_to receive(:start)
    expect(session_flow).not_to receive(:deliver_callback_output)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'ignores field click when payload command mismatches active session command' do
    session = double('Session', valid_user?: true, command: 'coffee')
    event = double('Event', data: 'field:echo:one:message:Hi', params: {}, user_id: 1)
    session_service = double('SessionService', find_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    expect(session_flow).not_to receive(:start)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'restarts flow when navigator returns :restart' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Echo'
      command 'echo'

      step :one do
        field :message do
          name 'Message'
        end
      end
    end

    session = double('Session', valid_user?: true, command: 'echo')
    event = double('Event', data: 'field:echo:one:message:Hi', params: {}, user_id: 1)
    session_service = double('SessionService', find_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    navigator = instance_double('PachcaHandlers::Flow::ButtonNavigator')
    allow(PachcaHandlers::Flow::ButtonNavigator).to receive(:new).and_return(navigator)
    allow(PachcaHandlers::Registry::HandlersRegistry).to receive(:get).with('echo').and_return(handler_class)

    allow(navigator).to receive(:parse_payload).and_return(['field', 'echo', :one, :message, 'Hi'])
    allow(navigator).to receive(:handle_field_click).and_return(:restart)

    expect(session_flow).to receive(:start)
    expect(session_flow).not_to receive(:deliver_callback_output)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end

  it 'delivers output and continues flow for normal navigator output' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Echo'
      command 'echo'

      step :one do
        field :message do
          name 'Message'
        end
      end
    end

    session = double('Session', valid_user?: true, command: 'echo')
    event = double('Event', data: 'field:echo:one:message:Hi', params: {}, user_id: 1)
    session_service = double('SessionService', find_session: session)
    session_flow = double('SessionFlow')
    message_service = double('MessageService')

    navigator = instance_double('PachcaHandlers::Flow::ButtonNavigator')
    allow(PachcaHandlers::Flow::ButtonNavigator).to receive(:new).and_return(navigator)
    allow(PachcaHandlers::Registry::HandlersRegistry).to receive(:get).with('echo').and_return(handler_class)

    allow(navigator).to receive(:parse_payload).and_return(['field', 'echo', :one, :message, 'Hi'])
    allow(navigator).to receive(:handle_field_click).and_return('ok')

    allow(handler_class).to receive(:steps).and_return([])

    expect(session_flow).to receive(:deliver_callback_output).with('ok')
    expect(session_flow).to receive(:start)

    build_processor(
      event: event,
      session_service: session_service,
      message_service: message_service,
      session_flow: session_flow
    ).process
  end
end
