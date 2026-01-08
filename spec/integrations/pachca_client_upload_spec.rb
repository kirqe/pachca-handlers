# frozen_string_literal: true

require 'stringio'

require_relative '../../lib/pachca_handlers/integrations/pachca_client'

RSpec.describe PachcaHandlers::Integrations::PachcaClient do
  it 'uploads a file and returns message file payload' do
    client = described_class.new
    allow(client).to receive(:request_upload_metadata).and_return(
      {
        'direct_url' => 'https://example.test/direct',
        'key' => 'attaches/files/1/uuid/${filename}',
        'acl' => 'private'
      }
    )

    expect(PachcaHandlers::Integrations::DirectUploader).to receive(:post).with(
      'https://example.test/direct',
      fields: hash_including('acl' => 'private'),
      file_io: kind_of(StringIO),
      filename: 'users.csv',
      content_type: 'text/csv'
    )

    io = StringIO.new("name,email\n")
    uploaded = client.upload_file(io, filename: 'users.csv', file_type: 'file', content_type: 'text/csv')

    expect(uploaded).to include(
      key: 'attaches/files/1/uuid/users.csv',
      name: 'users.csv',
      file_type: 'file',
      size: 11
    )
  end
end
