# frozen_string_literal: true

require 'tempfile'

require_relative 'base_client'

module PachcaHandlers
  module Integrations
    class FileDownloader
      class DownloadFailed < StandardError; end
      class DownloadTooLarge < StandardError; end

      DEFAULT_MAX_BYTES = 10 * 1024 * 1024

      def self.download(url, max_bytes: DEFAULT_MAX_BYTES, filename: nil, headers: {})
        response = BaseClient.get(url, {}, headers: headers)
        raise DownloadFailed, "HTTP #{response.status}" unless response.success?

        body = response.body
        body = body.to_s unless body.is_a?(String)

        if max_bytes && body.bytesize > max_bytes
          raise DownloadTooLarge, "File is too large (#{body.bytesize} bytes > #{max_bytes} bytes)"
        end

        ext = filename ? File.extname(filename.to_s) : ''
        tempfile = Tempfile.new(['pachca_handlers_upload', ext])
        tempfile.binmode
        tempfile.write(body)
        tempfile.rewind
        tempfile
      end
    end
  end
end
