# frozen_string_literal: true

require_relative 'base_client'

class PachcaClient < BaseClient
  BASE_URL = 'https://api.pachca.com/api/shared/v1'

  def initialize
    headers = {
      'Authorization' => "Bearer #{ENV.fetch('PACHCA_API_KEY', nil)}"
    }

    super(BASE_URL, headers)
  end

  def create_message(message)
    post('messages', message)
  end
end
