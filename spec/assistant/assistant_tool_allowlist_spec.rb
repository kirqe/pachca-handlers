# frozen_string_literal: true

require_relative '../spec_helper'

require_relative '../../lib/pachca_handlers/assistant/assistant'
require_relative '../../lib/pachca_handlers/registry/tools_registry'

RSpec.describe PachcaHandlers::Assistant::Assistant do
  before do
    PachcaHandlers::Registry::ToolsRegistry.instance_variable_set(:@tools, {})
  end

  it 'restricts tool definitions sent to the LLM client' do
    browse = Class.new
    close = Class.new

    PachcaHandlers::Registry::ToolsRegistry.register(browse, 'BrowseWeb')
    PachcaHandlers::Registry::ToolsRegistry.register(close, 'CloseSession')

    chat_data_manager = double('ChatDataManager')
    allow(chat_data_manager).to receive(:add_message)
    allow(chat_data_manager).to receive(:messages).and_return([{ role: 'user', content: 'q' }])

    response = double('Response')
    message = double('Message', tool_calls: [], content: 'hello')
    choice = double('Choice', message: message)
    allow(response).to receive(:choices).and_return([choice])

    llm_client = double('LLMClient')
    expect(llm_client).to receive(:chat_completion).with(
      [{ role: 'user', content: 'q' }],
      tools: [close],
      model: nil
    ).and_return(response)

    assistant = described_class.new(chat_data_manager: chat_data_manager, tool_names: ['CloseSession'],
                                    llm_client: llm_client)
    result = assistant.ask('q')

    expect(result).to be_a(PachcaHandlers::Result)
    expect(result.to_s).to eq('hello')
  end
end
