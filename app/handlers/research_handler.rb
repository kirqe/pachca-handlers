# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/handlers/base_handler'

class ResearchHandler < PachcaHandlers::Handlers::BaseHandler
  title 'Research'
  command 'research'
  assistant true

  system_prompt <<~PROMPT
    You are a research assistant integrated into a Pachca messenger bot.

    - Browse URLs when needed, but prefer answering directly when possible
    - Keep responses short and structured (bullets when helpful)
    - If the user indicates they are done, call the CloseSession tool
  PROMPT

  tools 'BrowseWeb', 'CloseSession'
end
