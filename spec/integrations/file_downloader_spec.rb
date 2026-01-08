# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/integrations/file_downloader'

RSpec.describe PachcaHandlers::Integrations::FileDownloader do
  it 'downloads into a tempfile' do
    response = instance_double('Faraday::Response', success?: true, status: 200, body: "name,email\nA,a@a\n")
    allow(PachcaHandlers::Integrations::BaseClient).to receive(:get).and_return(response)

    tempfile = described_class.download('https://example.test/users.csv', filename: 'users.csv')

    expect(File.extname(tempfile.path)).to eq('.csv')
    expect(tempfile.read).to include('name,email')
  ensure
    tempfile&.close!
  end

  it 'raises when file is too large' do
    response = instance_double('Faraday::Response', success?: true, status: 200, body: 'a' * 10)
    allow(PachcaHandlers::Integrations::BaseClient).to receive(:get).and_return(response)

    expect do
      described_class.download('https://example.test/big.bin', max_bytes: 5)
    end.to raise_error(PachcaHandlers::Integrations::FileDownloader::DownloadTooLarge)
  end
end
