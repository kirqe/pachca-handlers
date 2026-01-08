# frozen_string_literal: true

require 'base64'

require_relative 'base_client'

module PachcaHandlers
  module Integrations
    class YandexArtClient
      class Error < StandardError; end

      GENERATE_URL = 'https://llm.api.cloud.yandex.net/foundationModels/v1/imageGenerationAsync'
      OPERATIONS_URL = 'https://llm.api.cloud.yandex.net:443/operations'

      def initialize(api_key: nil, model_uri: nil)
        @api_key = (api_key || ENV.fetch('ART_API_KEY', nil)).to_s
        @model_uri = (model_uri || ENV.fetch('ART_MODEL_URL', nil)).to_s

        raise Error, 'Missing ART_API_KEY env var' if @api_key.empty?
        raise Error, 'Missing ART_MODEL_URL env var' if @model_uri.empty?
      end

      def generate_async(prompt:, width_ratio: '1', height_ratio: '1', seed: nil)
        payload = {
          modelUri: @model_uri,
          generationOptions: {
            aspectRatio: {
              widthRatio: width_ratio.to_s,
              heightRatio: height_ratio.to_s
            }
          },
          messages: [{ text: prompt.to_s }]
        }
        payload[:generationOptions][:seed] = seed.to_s if seed

        response = PachcaHandlers::Integrations::BaseClient.post(
          GENERATE_URL,
          payload,
          headers: authorization_header
        )

        raise Error, "generate failed: HTTP #{response.status}" unless response.success?

        operation_id = response.body['id'] || response.body[:id]
        raise Error, 'generate returned no operation id' if operation_id.to_s.empty?

        operation_id.to_s
      end

      def operation(operation_id)
        raise Error, 'operation_id is required' if operation_id.to_s.empty?

        PachcaHandlers::Integrations::BaseClient.get(
          "#{OPERATIONS_URL}/#{operation_id}",
          {},
          headers: authorization_header
        )
      end

      # Returns nil when still generating, otherwise returns image bytes.
      def fetch_image_bytes(operation_id)
        response = operation(operation_id)
        raise Error, "operation failed: HTTP #{response.status}" unless response.success?

        body = response.body
        return nil unless operation_done?(body)

        image_b64 = operation_image_b64(body)
        raise Error, 'No image in response' if image_b64.to_s.empty?

        decode_image_bytes(image_b64)
      end

      def operation_done?(operation_body)
        !!(operation_body['done'] || operation_body[:done])
      end

      def operation_image_b64(operation_body)
        operation_body.dig('response', 'image') || operation_body.dig(:response, :image)
      end

      def decode_image_bytes(image_b64)
        Base64.decode64(image_b64.to_s)
      end

      private

      def authorization_header
        { 'Authorization' => "Api-Key #{@api_key}" }
      end
    end
  end
end
