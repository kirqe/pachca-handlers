# frozen_string_literal: true

require 'tempfile'

require 'faraday'
require 'faraday/multipart'

module PachcaHandlers
  module Integrations
    class DirectUploader
      class UploadFailed < StandardError; end

      def self.post(url, fields:, file_io:, filename:, content_type: 'application/octet-stream')
        with_tempfile(file_io, filename) do |tmp|
          file_part = Faraday::Multipart::FilePart.new(tmp.path, content_type.to_s, filename.to_s)
          payload = fields.merge('file' => file_part)

          response = Faraday.new(url: url.to_s) do |f|
            f.request :multipart
            f.request :url_encoded
            f.adapter Faraday.default_adapter
          end.post('', payload)

          return response if response.success?

          raise UploadFailed, "Upload failed: HTTP #{response.status}"
        end
      end

      def self.with_tempfile(file_io, filename)
        ext = File.extname(filename.to_s)
        tmp = Tempfile.new(['pachca_handlers_upload', ext])
        tmp.binmode
        file_io.rewind if file_io.respond_to?(:rewind)
        tmp.write(file_io.read.to_s)
        tmp.rewind
        yield tmp
      ensure
        tmp&.close!
      end
      private_class_method :with_tempfile
    end
  end
end
