# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/flow/session_flow'
require_relative '../../lib/pachca_handlers/result'

RSpec.describe PachcaHandlers::Flow::SessionFlow do
  let(:event) { instance_double('Event') }
  let(:steps_data_manager) { instance_double('StepsDataManager', mark_emitted_output!: true) }
  let(:session) { instance_double('Session', steps_data_manager: steps_data_manager) }
  let(:session_service) { instance_double('SessionService', find_session: session) }
  let(:message_service) do
    instance_double('MessageService', deliver: true, post_result: true)
  end

  subject(:flow) do
    described_class.new(event: event, session_service: session_service, message_service: message_service)
  end

  it 'delivers a String output and marks emitted output' do
    expect(message_service).to receive(:deliver).with('hi')
    expect(steps_data_manager).to receive(:mark_emitted_output!).once

    flow.deliver_callback_output('hi')
  end

  it 'posts a Result output and marks emitted output' do
    result = PachcaHandlers::Result.success('ok')

    expect(message_service).to receive(:post_result).with(result)
    expect(steps_data_manager).to receive(:mark_emitted_output!).once

    flow.deliver_callback_output(result)
  end

  it 'delivers nested array outputs in order' do
    result = PachcaHandlers::Result.success('ok')

    expect(message_service).to receive(:deliver).with('a').ordered
    expect(message_service).to receive(:post_result).with(result).ordered
    expect(message_service).to receive(:deliver).with('b').ordered
    expect(steps_data_manager).to receive(:mark_emitted_output!).exactly(3).times

    flow.deliver_callback_output(['a', [result], 'b'])
  end

  it 'restarts the flow for :restart output' do
    allow(flow).to receive(:start)

    expect(steps_data_manager).to receive(:mark_emitted_output!).once
    expect(flow).to receive(:start).once

    flow.deliver_callback_output(:restart)
  end
end
