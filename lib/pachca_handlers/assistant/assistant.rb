# frozen_string_literal: true

require_relative '../registry/tools_registry'
require_relative '../integrations/llm_client'
require_relative '../result'

module PachcaHandlers
  module Assistant
    class Assistant
      def initialize(chat_data_manager:, tool_names: nil, model: nil, llm_client: nil)
        @chat_data_manager = chat_data_manager
        @model = model
        @allowed_tool_names = tool_names&.map(&:to_s)
        @client = llm_client || PachcaHandlers::Integrations::LLMClient.new
      end

      def ask(question, context: {})
        @chat_data_manager.add_message(role: 'user', content: question)

        response = @client.chat_completion(
          @chat_data_manager.messages,
          tools: tool_definitions,
          model: @model
        )
        tool_calls = response.choices.flat_map { |choice| choice.message.tool_calls.to_a }
        result = run_tools(tool_calls, context: context)

        content = result.any? ? result.join("\n") : response.choices.first.message.content
        @chat_data_manager.add_message(role: 'assistant', content: content)

        content.is_a?(PachcaHandlers::Result) ? content : PachcaHandlers::Result.success(content)
      end

      private

      def tool_definitions
        return nil unless @allowed_tool_names

        @allowed_tool_names.map do |name|
          tool = PachcaHandlers::Registry::ToolsRegistry.get(name)
          raise KeyError, "Unknown tool: #{name}" unless tool

          tool
        end
      end

      def run_tools(tool_calls, context: {})
        tool_calls.map do |tool_call|
          name = tool_call.function.name.to_s
          if @allowed_tool_names && !@allowed_tool_names.include?(name)
            next PachcaHandlers::Result.error("Tool not allowed: #{name}")
          end

          tool = PachcaHandlers::Registry::ToolsRegistry.get(name)
          next PachcaHandlers::Result.error("Tool not found: #{name}") unless tool

          args = tool_call.function.parsed || {}
          tool.call(**args, runtime_context: context)
        end
      end
    end
  end
end
