# frozen_string_literal: true

require 'stringio'

require_relative '../../lib/pachca_handlers/integrations/direct_uploader'

RSpec.describe PachcaHandlers::Integrations::DirectUploader do
  it 'posts multipart form with file' do
    conn = instance_double('Faraday::Connection')
    response = instance_double('Faraday::Response', success?: true, status: 201)

    allow(Faraday).to receive(:new).and_return(conn)
    expect(conn).to receive(:post) do |_, payload|
      expect(payload).to include('acl' => 'private')
      expect(payload['file']).to be_a(Faraday::Multipart::FilePart)
      response
    end

    described_class.post(
      'https://example.test/direct',
      fields: { 'acl' => 'private' },
      file_io: StringIO.new('hello'),
      filename: 'hello.txt',
      content_type: 'text/plain'
    )
  end

  it 'raises on non-success response' do
    conn = instance_double('Faraday::Connection')
    response = instance_double('Faraday::Response', success?: false, status: 400)

    allow(Faraday).to receive(:new).and_return(conn)
    allow(conn).to receive(:post).and_return(response)

    expect do
      described_class.post(
        'https://example.test/direct',
        fields: {},
        file_io: StringIO.new('hello'),
        filename: 'hello.txt'
      )
    end.to raise_error(PachcaHandlers::Integrations::DirectUploader::UploadFailed)
  end
end
