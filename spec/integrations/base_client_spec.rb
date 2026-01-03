# frozen_string_literal: true

require 'faraday'

require_relative '../../lib/pachca_handlers/integrations/base_client'

RSpec.describe PachcaHandlers::Integrations::BaseClient do
  it 'supports class-level POST with JSON encoding' do
    request_body = nil
    request_content_type = nil

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('/') do |env|
        request_body = env.body
        request_content_type = env.request_headers['Content-Type']
        [200, { 'Content-Type' => 'application/json' }, '{"ok":true}']
      end
    end

    conn = Faraday.new(url: 'https://example.test') do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter :test, stubs
    end

    allow(Faraday).to receive(:new).and_wrap_original do |original, *args, **kwargs, &block|
      url = kwargs[:url] || args.first&.dig(:url)
      if url.to_s == 'https://example.test'
        conn
      else
        original.call(*args, **kwargs, &block)
      end
    end

    response = described_class.post('https://example.test', { a: 1 })

    expect(response).to be_success
    expect(response.body).to eq({ 'ok' => true })
    expect(request_body).to eq('{"a":1}')
    expect(request_content_type).to start_with('application/json')

    stubs.verify_stubbed_calls
  end
end
