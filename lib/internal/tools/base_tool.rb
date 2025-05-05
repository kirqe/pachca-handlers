# frozen_string_literal: true

require 'bundler/setup'
require 'openai'
require_relative '../tools_registry'

class BaseTool < OpenAI::BaseModel
  class << self
    def inherited(subclass)
      super
      ToolsRegistry.register(subclass, subclass.name.split('::').last)
    end

    def call
      raise NotImplementedError
    end
  end
end
