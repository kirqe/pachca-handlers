# frozen_string_literal: true

require 'json'
require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/integrations/base_client'

class NetworkHandler < PachcaHandlers::Handlers::BaseHandler
  title 'Network Call'
  command 'network'

  step :api_call do
    callback do
      response = PachcaHandlers::Integrations::BaseClient.get('https://jsonplaceholder.typicode.com/posts/1')

      if response.success?
        data = response.body
        PachcaHandlers::Result.success(format_response(data))
      else
        PachcaHandlers::Result.error("Failed to fetch data: HTTP #{response.status}")
      end
    rescue StandardError => e
      PachcaHandlers::Result.error("Network error: #{e.message}")
    end
  end

  private

  def format_response(data)
    [
      '```',
      JSON.pretty_generate(data),
      '```'
    ].join("\n")
  end
end
