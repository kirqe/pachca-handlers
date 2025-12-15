# frozen_string_literal: true

require 'bundler/setup'
require 'openai'
require_relative '../registry/tools_registry'

module PachcaHandlers
  module Integrations
    class LLMClient
      def initialize
        @client = OpenAI::Client.new(
          api_key: ENV.fetch('LLM_API_KEY'),
          base_url: ENV.fetch('LLM_API_BASE_URL')
        )
      end

      def chat_completion(messages, tools: nil, model: nil)
        @client.chat.completions.create(
          model: model || ENV.fetch('LLM_MODEL'),
          messages: messages,
          tools: tools.nil? ? PachcaHandlers::Registry::ToolsRegistry.all.values : tools
        )
      end
    end
  end
end
