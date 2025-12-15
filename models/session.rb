# frozen_string_literal: true

require 'sequel'
require_relative '../lib/pachca_handlers/flow/steps_data_manager'
require_relative '../lib/pachca_handlers/assistant/chat_data_manager'

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
    @steps_data_manager ||= PachcaHandlers::Flow::StepsDataManager.new(self)
  end

  def initialize_steps_data!
    return if steps_data != '{}'

    steps_data_manager.prepare!
  end

  def chat_data_manager
    @chat_data_manager ||= PachcaHandlers::Assistant::ChatDataManager.new(self)
  end

  def initialize_chat_data!(system_prompt: nil)
    return if chat_data != '{}'

    prompt = system_prompt || I18n.t('instructions.assistant')
    chat_data_manager.add_message(role: 'system', content: prompt)
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
