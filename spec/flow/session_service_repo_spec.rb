# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/flow/session_service'

RSpec.describe PachcaHandlers::Flow::SessionService do
  let(:event) do
    double(
      'Event',
      user_id: 1,
      chat_id: 2,
      entity_type: 'discussion',
      entity_id: 3,
      command: 'echo'
    )
  end

  it 'returns an existing active session' do
    repo = instance_double('SessionRepo')
    session = Object.new

    expect(repo).to receive(:find_active).and_return(session)
    service = described_class.new(event, session_repo: repo)

    expect(service.find_or_create_session).to be(session)
  end

  it 'creates a session when none exists' do
    repo = instance_double('SessionRepo')
    session = Object.new

    expect(repo).to receive(:find_active).and_return(nil)
    expect(repo).to receive(:create_active).with(
      user_id: 1,
      chat_id: 2,
      entity_type: 'discussion',
      entity_id: 3,
      command: 'echo'
    ).and_return(session)

    service = described_class.new(event, session_repo: repo)
    expect(service.find_or_create_session).to be(session)
  end

  it 'cancels existing active sessions for a user and chat' do
    repo = instance_double('SessionRepo')
    expect(repo).to receive(:cancel_active_for_user).with(user_id: 1, chat_id: 2)

    service = described_class.new(event, session_repo: repo)
    service.cancel_existing_sessions
  end
end
