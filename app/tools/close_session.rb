# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/assistant/base_tool'

class CloseSession < PachcaHandlers::Assistant::BaseTool
  required :context, String, doc: 'Context whether session with user can be closed'

  def self.call(context:, runtime_context: {})
    _ = context
    session = runtime_context[:session]
    return PachcaHandlers::Result.success(I18n.t('messages.session_not_found')) unless session

    session.complete!
    PachcaHandlers::Result.success(I18n.t('messages.session_finished'))
  end
end
