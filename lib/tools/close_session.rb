# frozen_string_literal: true

require_relative '../internal/tools/base_tool'

class CloseSession < BaseTool
  required :context, String, doc: 'Context wether session with usercan be closed'

  def self.call(context:, runtime_context: {})
    _ = context
    session = runtime_context[:session]
    return Result.success(I18n.t('messages.session_not_found')) unless session

    session.complete!
    Result.success(I18n.t('messages.session_finished'))
  end
end
