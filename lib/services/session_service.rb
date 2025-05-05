# frozen_string_literal: true

require_relative '../../models/session'

class SessionService
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def find_or_create_session
    params = {
      user_id: event.user_id,
      chat_id: event.chat_id,
      entity_type: event.entity_type,
      entity_id: event.entity_id,
      status: Session::STATUSES[:active]
    }

    session = Session.find(params)
    return session if session

    params[:command] = event.command
    Session.create(params)
  end

  def find_session
    params = {
      user_id: event.user_id,
      chat_id: event.chat_id,
      entity_type: event.entity_type,
      entity_id: event.entity_id,
      status: Session::STATUSES[:active]
    }

    Session.find(params)
  end
end
