# frozen_string_literal: true

require 'i18n'
require_relative '../spec_helper'

require_relative '../../lib/pachca_handlers/assistant/assistant_session_flow'
require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/registry/handlers_registry'
require_relative '../../lib/pachca_handlers/result'

RSpec.describe PachcaHandlers::Assistant::AssistantSessionFlow do
  before do
    PachcaHandlers::Registry::HandlersRegistry.instance_variable_set(:@handlers, {})

    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, messages: { assistant_welcome: 'Welcome' },
                                         instructions: { assistant: 'DEFAULT' })
    I18n.default_locale = :en
  end

  it 'uses assistant handler DSL for system_prompt and tool allowlist' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Research'
      command 'research'
      assistant true
      system_prompt 'RESEARCH_PROMPT'
      tools 'BrowseWeb', 'CloseSession'
    end

    chat_data_manager = double('ChatDataManager')
    session = double('Session', command: handler_class.command, chat_data_manager: chat_data_manager)
    session_service = double('SessionService', find_session: session)
    message_service = double('MessageService')

    assistant = double('Assistant', ask: PachcaHandlers::Result.success('ok'))
    stub_const('PachcaHandlers::Assistant::Assistant', Class.new)
    expect(PachcaHandlers::Assistant::Assistant).to receive(:new).with(
      chat_data_manager: chat_data_manager,
      tool_names: %w[BrowseWeb CloseSession],
      model: nil
    ).and_return(assistant)

    expect(session).to receive(:initialize_chat_data!).with(system_prompt: 'RESEARCH_PROMPT')
    expect(message_service).to receive(:deliver)

    event = double('Event', content: '/research hello', command?: true, command: 'research')
    described_class.new(event: event, session_service: session_service, message_service: message_service).continue
  end

  it 'defaults assistant tools to CloseSession when tools are not declared' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Ask'
      command 'ask'
      assistant true
      system_prompt 'PROMPT'
    end

    chat_data_manager = double('ChatDataManager')
    session = double('Session', command: handler_class.command, chat_data_manager: chat_data_manager)
    session_service = double('SessionService', find_session: session)
    message_service = double('MessageService')

    assistant = double('Assistant', ask: PachcaHandlers::Result.success('ok'))
    stub_const('PachcaHandlers::Assistant::Assistant', Class.new)
    expect(PachcaHandlers::Assistant::Assistant).to receive(:new).with(
      chat_data_manager: chat_data_manager,
      tool_names: ['CloseSession'],
      model: nil
    ).and_return(assistant)

    allow(session).to receive(:initialize_chat_data!)
    allow(message_service).to receive(:deliver)

    event = double('Event', content: '/ask hello', command?: true, command: 'ask')
    described_class.new(event: event, session_service: session_service, message_service: message_service).continue
  end

  it 'strips the command prefix when the user sends "/<command> ..."' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Ask'
      command 'ask'
      assistant true
      system_prompt 'PROMPT'
      tools 'CloseSession'
    end

    chat_data_manager = double('ChatDataManager')
    session = double('Session', command: handler_class.command, chat_data_manager: chat_data_manager)
    session_service = double('SessionService', find_session: session)
    message_service = double('MessageService')

    assistant = double('Assistant')
    expect(assistant).to receive(:ask).with('hello', context: { session: session }).and_return(PachcaHandlers::Result.success('ok'))

    stub_const('PachcaHandlers::Assistant::Assistant', Class.new)
    allow(PachcaHandlers::Assistant::Assistant).to receive(:new).and_return(assistant)

    allow(session).to receive(:initialize_chat_data!)
    allow(message_service).to receive(:deliver)

    event = double('Event', content: '/ask hello', command?: true, command: 'ask')
    described_class.new(event: event, session_service: session_service, message_service: message_service).continue
  end
end
