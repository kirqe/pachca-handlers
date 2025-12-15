# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/flow/output'
require_relative '../../lib/pachca_handlers/result'

RSpec.describe PachcaHandlers::Flow::Output do
  it 'normalizes nil to empty output' do
    out = described_class.from(nil)
    expect(out.messages).to eq([])
    expect(out.restart?).to eq(false)
  end

  it 'normalizes String to a message' do
    out = described_class.from('hello')
    expect(out.messages).to eq(['hello'])
    expect(out.restart?).to eq(false)
  end

  it 'normalizes Result to a message' do
    result = PachcaHandlers::Result.success('ok')
    out = described_class.from(result)
    expect(out.messages).to eq([result])
    expect(out.restart?).to eq(false)
  end

  it 'normalizes :restart to restart output' do
    out = described_class.from(:restart)
    expect(out.messages).to eq([])
    expect(out.restart?).to eq(true)
  end

  it 'normalizes nested arrays and preserves restart' do
    result = PachcaHandlers::Result.success('ok')
    out = described_class.from(['a', [result, :restart], nil])
    expect(out.messages).to eq(['a', result])
    expect(out.restart?).to eq(true)
  end
end
