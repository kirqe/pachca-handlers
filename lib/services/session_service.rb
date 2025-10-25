# frozen_string_literal: true

require_relative '../../models/session'

class SessionService
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def find_or_create_session
    session = find_session
    return session if session

    params = base_params.merge(command: event.command)
    Session.create(params)
  end

  def find_session
    Session.find(base_params)
  end

  def cancel_existing_sessions
    Session.where(
      user_id: @event.user_id,
      chat_id: @event.chat_id,
      status: Session::STATUSES[:active]
    ).update(status: Session::STATUSES[:finished])
  end

  private

  def base_params
    {
      user_id: @event.user_id,
      chat_id: @event.chat_id,
      entity_type: @event.entity_type,
      entity_id: @event.entity_id,
      status: Session::STATUSES[:active]
    }
  end
end
