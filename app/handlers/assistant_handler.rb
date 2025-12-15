# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/handlers/base_handler'

class AssistantHandler < PachcaHandlers::Handlers::BaseHandler
  title 'Generic Assistant'
  command 'ask'
  assistant true
  system_prompt_i18n 'instructions.assistant'
  tools 'CloseSession'
end
