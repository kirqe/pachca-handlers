# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/internal/events/message_event'

RSpec.describe MessageEvent do
  let(:params) do
    {
      'event' => 'new',
      'type' => 'message',
      'chat_id' => 23_558_096,
      'user_id' => 415_758,
      'id' => 517_760_513,
      'content' => '/test',
      'entity_type' => 'discussion',
      'entity_id' => 23_558_096
    }
  end

  describe 'attributes' do
    let(:event) { MessageEvent.new(params) }

    it 'returns the type of the event' do
      expect(event.type).to eq('message')
    end

    it 'extracts command' do
      expect(event.command?).to be_truthy
      expect(event.command).to eq('test')
    end

    it 'method_missing' do
      expect(event.chat_id).to eq(23_558_096)
    end
  end
end
