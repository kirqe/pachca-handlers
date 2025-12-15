# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/webhook/endpoint'

RSpec.describe PachcaHandlers::Webhook::Endpoint do
  it 'uses the injected container to build and run a processor' do
    container = instance_double('PachcaHandlers::Container')
    processor = instance_double('Processor', process: true)

    expect(container).to receive(:build_event_processor).and_return(processor)

    endpoint = described_class.new(container: container)
    endpoint.call('type' => 'message', 'content' => '/start')
  end
end
