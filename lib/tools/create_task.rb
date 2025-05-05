# frozen_string_literal: true

require_relative '../internal/tools/base_tool'

class CreateTask < BaseTool
  required :summary, String, doc: 'Summary of the task to be created'
  required :description, String, doc: 'Description of the task to be created'

  def self.call(summary:, description:, queue: 'MYQUEUE', runtime_context: {})
    _ = runtime_context
    response = YandexTrackerClient.new.create_task(queue:, summary:, description:)

    if response.success?
      issue_key = response.body['key']
      url = "https://tracker.yandex.ru/#{issue_key}"

      Result.success(url)
    else
      Result.error([I18n.t('messages.something_went_wrong')])
    end
  end
end
