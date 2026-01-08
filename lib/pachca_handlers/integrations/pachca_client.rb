# frozen_string_literal: true

require_relative 'base_client'
require_relative 'direct_uploader'

module PachcaHandlers
  module Integrations
    class PachcaClient < BaseClient
      BASE_URL = 'https://api.pachca.com/api/shared/v1'

      def initialize
        headers = {
          'Authorization' => "Bearer #{ENV.fetch('PACHCA_API_KEY', nil)}"
        }

        super(BASE_URL, headers)
      end

      def create_message(message)
        post('messages', message)
      end

      def update_message(message_id, message)
        put("messages/#{message_id}", message)
      end

      def get_message(message_id)
        get("messages/#{message_id}")
      end

      def upload_file(file_io, filename:, file_type: 'file', content_type: nil)
        metadata = request_upload_metadata
        direct_url = metadata.fetch('direct_url')

        key_template = metadata.fetch('key')
        form_fields = metadata.dup
        form_fields.delete('direct_url')

        PachcaHandlers::Integrations::DirectUploader.post(
          direct_url,
          fields: form_fields,
          file_io: file_io,
          filename: filename,
          content_type: content_type || 'application/octet-stream'
        )

        {
          key: key_template.to_s.gsub('${filename}', filename.to_s),
          name: filename.to_s,
          file_type: file_type.to_s,
          size: file_size(file_io)
        }
      end

      private

      def request_upload_metadata
        response = post('uploads', {})
        body = response.body
        body = body['data'] if body.is_a?(Hash) && body.key?('data')
        body = body.transform_keys(&:to_s) if body.is_a?(Hash)
        return body if body.is_a?(Hash)

        raise TypeError, "Unexpected uploads response: #{body.class}"
      end

      def file_size(file_io)
        return file_io.size if file_io.respond_to?(:size)

        bytes = file_io.read.to_s.bytesize
        file_io.rewind if file_io.respond_to?(:rewind)
        bytes
      end
    end
  end
end
