# frozen_string_literal: true

require_relative '../internal/handlers/base_handler'

class MeHandler < BaseHandler
  title 'Me'
  command 'me'

  step :me do
    intro 'This is the Me handler. It will return information about the current user.'
  end

  def perform
    response = PachcaClient.new.get("users/#{params['user_id']}")
    formatted_data = format_user_data(response.body['data'])

    Result.success(formatted_data)
  end

  private

  def format_user_data(data)
    [
      "ID: #{data['id']}",
      "First Name: #{data['first_name']}",
      "Last Name: #{data['last_name']}",
      "Email: #{data['email']}",
      "Phone: #{data['phone_number']}",
      "Department: #{data['department']}",
      "Role: #{data['role']}",
      "Suspended: #{data['suspended']}",
      "Title: #{data['title']}",
      "Timezone: #{data['time_zone']}"
    ].join("\n")
  end
end
