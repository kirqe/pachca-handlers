# frozen_string_literal: true

require 'bundler/setup'
require 'openai'
require_relative '../../internal/tools_registry'

class LLMClient
  def initialize
    @client = OpenAI::Client.new(
      api_key: ENV.fetch('LLM_API_KEY'),
      base_url: ENV.fetch('LLM_API_BASE_URL')
    )
  end

  def chat_completion(messages)
    @client.chat.completions.create(
      model: ENV.fetch('LLM_MODEL'),
      messages: messages,
      tools: ToolsRegistry.all.values
    )
  end
end
