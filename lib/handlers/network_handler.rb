# frozen_string_literal: true

require_relative '../internal/handlers/base_handler'

class NetworkHandler < BaseHandler
  title 'Network Call'
  command 'network'

  step :api_call do
    callback do |ctx|
      begin
        response = BaseClient.get('https://jsonplaceholder.typicode.com/posts/1')

        if response.success?
          data = response.body
          formatted_response = ctx[:handler].send(:format_response, data)
          Result.success(formatted_response)
        else
          Result.error("Failed to fetch data: HTTP #{response.status}")
        end
      rescue => e
        Result.error("Network error: #{e.message}")
      end
    end
  end

  private

  def format_response(data)
    [
      "```",
      JSON.pretty_generate(data),
      "```"
    ].join("\n")
  end
end
