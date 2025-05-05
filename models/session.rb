# frozen_string_literal: true

require_relative '../lib/internal/steps_data_manager'
require_relative '../lib/internal/chat_data_manager'

class Session < Sequel::Model
  STATUSES = {
    active: 0,
    finished: 1,
    cancelled: 2,
    expired: 3
  }.freeze

  # TYPES = {
  #   handler: 0,
  #   assistant: 1
  # }.freeze

  def validate
    super
    errors.add(:command, 'is required') if command.nil? || command.empty?
  end

  def steps_data_manager
    @steps_data_manager ||= StepsDataManager.new(self)
  end

  def initialize_steps_data!
    return if steps_data != '{}'

    steps_data_manager.prepare!
  end

  def chat_data_manager
    @chat_data_manager ||= ChatDataManager.new(self)
  end

  def initialize_chat_data!
    return if chat_data != '{}'

    chat_data_manager.add_message(role: 'system', content: I18n.t('instructions.assistant'))
  end

  def valid_user?(user_id)
    self[:user_id] == user_id
  end

  def expired?
    return false unless expires_at

    if expires_at < Time.now
      update(status: STATUSES[:expired])
      return true
    end

    false
  end

  def cancel!
    update(status: STATUSES[:cancelled])
  end

  def complete!
    update(status: STATUSES[:finished])
  end
end
