# frozen_string_literal: true

require 'i18n'
require_relative '../spec_helper'

require_relative '../../lib/pachca_handlers/webhook/event_processor'

RSpec.describe PachcaHandlers::Webhook::EventProcessor do
  before do
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, messages: { something_went_wrong: 'oops' })
    I18n.default_locale = :en

    allow(Kernel).to receive(:warn)
  end

  it 'delivers something_went_wrong when processing raises' do
    processor_class = Class.new(described_class) do
      def process!
        raise 'boom'
      end
    end

    message_service = instance_double('MessageService')
    expect(message_service).to receive(:deliver).with('oops')

    processor_class.new(
      event: double('Event'),
      session_service: double('SessionService'),
      message_service: message_service,
      session_flow: double('SessionFlow')
    ).process
  end
end
