# frozen_string_literal: true

require_relative '../internal/clients/base_client'

class YandexTrackerClient < BaseClient
  BASE_URL = 'https://api.tracker.yandex.net/v3'

  def initialize
    headers = {
      'Authorization' => "OAuth #{ENV.fetch('YANDEX_TRACKER_OAUTH_TOKEN', nil)}",
      'X-Org-ID' => ENV.fetch('YANDEX_TRACKER_ORG_ID', nil)
    }

    super(BASE_URL, headers)
  end

  def create_task(task)
    post('issues', task)
  end
end
