# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :sessions do
      primary_key :id
      Integer :type, null: false, default: 0, index: true # unused
      String :command, null: false, index: true
      Integer :status, null: false, default: 0, index: true
      DateTime :expires_at # unused
      String :steps_data, null: false, default: '{}'
      Integer :user_id, null: false, index: true
      String :entity_type, null: false
      Integer :entity_id, null: false
      Integer :chat_id, null: false, index: true
      Integer :message_id
      String :user_data, null: false, default: '{}' # unused
      String :chat_data, null: false, default: '{}'
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP, on_update: Sequel::CURRENT_TIMESTAMP

      index %i[user_id chat_id status]
    end
  end
end
