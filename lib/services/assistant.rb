# frozen_string_literal: true

require_relative '../internal/tools_registry'
require_relative '../internal/clients/llm_client'

class Assistant
  def initialize(chat_data_manager:)
    @chat_data_manager = chat_data_manager
    @client = LLMClient.new
  end

  def ask(question, context: {})
    response = @client.chat_completion(@chat_data_manager.messages + [{ role: 'user', content: question }])
    result = run_tools(response.choices.flat_map { _1.message.tool_calls.to_a }, context: context)

    content = result.any? ? result.join("\n") : response.choices.first.message.content
    @chat_data_manager.add_message(role: 'assistant', content: content)

    content.is_a?(Result) ? content : Result.success(content)
  end

  private

  def run_tools(tool_calls, context: {})
    tool_calls.map do |tool_call|
      tool = ToolsRegistry.get(tool_call.function.name)

      args = tool_call.function.parsed || {}
      tool.call(**args, runtime_context: context)
    end
  end
end
