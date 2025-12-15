# frozen_string_literal: true

require 'bundler/setup'
require 'openai'
require_relative '../registry/tools_registry'

module PachcaHandlers
  module Assistant
    class BaseTool < OpenAI::BaseModel
      class << self
        def inherited(subclass)
          super
          PachcaHandlers::Registry::ToolsRegistry.register(subclass, subclass.name.split('::').last)
        end

        def call
          raise NotImplementedError
        end
      end
    end
  end
end
