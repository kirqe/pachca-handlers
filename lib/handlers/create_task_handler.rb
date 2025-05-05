# frozen_string_literal: true

require_relative '../clients/yandex_tracker_client'
require_relative '../internal/handlers/base_handler'

# Handler for creating a task in Yandex Tracker
#
# Usage:
#   /create_task summary="Task summary" description="Task description"
#   /create_task "Task summary. Task description"
#
class CreateTaskHandler < BaseHandler
  title 'Create task'
  command 'create_task'

  QUEUE = 'MYQUEUE'

  def perform
    inline_params = params[:inline_params]
    task_params = build_task_params(inline_params)

    response = YandexTrackerClient.new.create_task(task_params)

    if response.success?
      issue_key = response.body['key']
      url = "https://tracker.yandex.ru/#{issue_key}"

      Result.success(url)
    else
      Result.error([I18n.t('messages.something_went_wrong')])
    end
  end

  private

  def build_task_params(params)
    summary = params.fetch(:summary, nil)
    description = params.fetch(:description, nil)
    message = params.fetch(:message, nil)

    if message
      summary = message.split('.').first
      description = message
    end

    {
      queue: QUEUE,
      summary: summary,
      description: description
    }
  end
end
