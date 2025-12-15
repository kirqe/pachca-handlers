# frozen_string_literal: true

require_relative '../../lib/internal/handlers/base_handler'

class AssistantHandler < BaseHandler
  title 'Assistant'
  command 'ask'
  assistant true
end
