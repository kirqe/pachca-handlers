# frozen_string_literal: true

require_relative '../internal/handlers/base_handler'
require_relative '../services/assistant'

class AssistantHandler < BaseHandler
  title 'Assistant'
  command 'ask'
  assistant true
end
