# frozen_string_literal: true

require 'base64'
require_relative '../../lib/pachca_handlers/integrations/yandex_art_client'

RSpec.describe PachcaHandlers::Integrations::YandexArtClient do
  it 'starts an async generation and returns operation id' do
    response = instance_double('Faraday::Response', success?: true, status: 200, body: { 'id' => 'op123' })
    expect(PachcaHandlers::Integrations::BaseClient).to receive(:post) do |url, payload, headers:|
      expect(url).to eq(described_class::GENERATE_URL)
      expect(headers).to eq('Authorization' => 'Api-Key key')
      expect(payload[:modelUri]).to eq('model')
      expect(payload[:messages]).to eq([{ text: 'hi' }])
      response
    end

    client = described_class.new(api_key: 'key', model_uri: 'model')
    expect(client.generate_async(prompt: 'hi')).to eq('op123')
  end

  it 'raises on non-success generation response' do
    response = instance_double('Faraday::Response', success?: false, status: 403, body: {})
    allow(PachcaHandlers::Integrations::BaseClient).to receive(:post).and_return(response)

    client = described_class.new(api_key: 'key', model_uri: 'model')
    expect { client.generate_async(prompt: 'hi') }.to raise_error(described_class::Error, /HTTP 403/)
  end

  it 'fetches operation status' do
    response = instance_double('Faraday::Response', success?: true, status: 200, body: { 'done' => true })
    expect(PachcaHandlers::Integrations::BaseClient).to receive(:get).with(
      "#{described_class::OPERATIONS_URL}/op123",
      {},
      headers: { 'Authorization' => 'Api-Key key' }
    ).and_return(response)

    client = described_class.new(api_key: 'key', model_uri: 'model')
    expect(client.operation('op123')).to eq(response)
  end

  it 'returns nil from fetch_image_bytes when still generating' do
    response = instance_double('Faraday::Response', success?: true, status: 200, body: { 'done' => false })
    allow(PachcaHandlers::Integrations::BaseClient).to receive(:get).and_return(response)

    client = described_class.new(api_key: 'key', model_uri: 'model')
    expect(client.fetch_image_bytes('op123')).to be_nil
  end

  it 'returns decoded bytes from fetch_image_bytes when done' do
    image_bytes = 'jpeg-bytes'
    body = { 'done' => true, 'response' => { 'image' => Base64.strict_encode64(image_bytes) } }
    response = instance_double('Faraday::Response', success?: true, status: 200, body: body)
    allow(PachcaHandlers::Integrations::BaseClient).to receive(:get).and_return(response)

    client = described_class.new(api_key: 'key', model_uri: 'model')
    expect(client.fetch_image_bytes('op123')).to eq(image_bytes)
  end

  it 'raises from fetch_image_bytes on non-success response' do
    response = instance_double('Faraday::Response', success?: false, status: 403, body: {})
    allow(PachcaHandlers::Integrations::BaseClient).to receive(:get).and_return(response)

    client = described_class.new(api_key: 'key', model_uri: 'model')
    expect { client.fetch_image_bytes('op123') }.to raise_error(described_class::Error, /HTTP 403/)
  end
end
