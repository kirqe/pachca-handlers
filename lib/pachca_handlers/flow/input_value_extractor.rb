# frozen_string_literal: true

module PachcaHandlers
  module Flow
    class InputValueExtractor
      def initialize(event:, message_service:)
        @event = event
        @message_service = message_service
      end

      def value_for(field)
        case field.input
        when :file
          files_for_file_input.first
        when :files
          files_for_file_input
        else
          @event.content
        end
      end

      def missing_input_error(field, value)
        return I18n.t('messages.errors.message_text_required') if field.input == :text && value.nil?

        if file_input?(field) && (value.nil? || (value.is_a?(Array) && value.empty?))
          return I18n.t('messages.errors.file_attachment_required')
        end

        nil
      end

      private

      def file_input?(field)
        %i[file files].include?(field.input)
      end

      def files_for_file_input
        raw_files = webhook_files
        raw_files = api_files if raw_files.empty?

        raw_files.map { |file| normalize_file(file) }.compact.select { |file| valid_file?(file) }
      rescue StandardError # never crash the flow on file parsing
        []
      end

      def webhook_files
        params = @event.params || {}

        raw =
          hget(params, :files) ||
          hget(params, :attachments) ||
          hdig(params, :message, :files) ||
          hdig(params, :message, :attachments) ||
          hdig(params, :data, :files) ||
          hdig(params, :data, :attachments)

        normalize_to_array(raw)
      end

      def api_files
        message_id = message_id_from_params
        return [] unless message_id
        return [] unless @message_service.respond_to?(:fetch_message)

        message = @message_service.fetch_message(message_id) || {}
        raw = hget(message, :files)
        normalize_to_array(raw)
      end

      def normalize_to_array(value)
        return [] if value.nil?
        return value if value.is_a?(Array)

        [value]
      end

      def message_id_from_params
        params = @event.params || {}
        params['id'] || params[:id] || params.dig('message', 'id') || params.dig(:message, :id)
      end

      def hget(hash, key)
        return nil unless hash.is_a?(Hash)

        hash[key] || hash[key.to_s] || hash[key.to_sym]
      end

      def hdig(hash, *path)
        path.reduce(hash) do |acc, key|
          next nil unless acc.is_a?(Hash)

          hget(acc, key)
        end
      end

      def normalize_file(file)
        return nil unless file

        {
          id: file[:id] || file['id'],
          key: file[:key] || file['key'],
          name: file[:name] || file['name'],
          file_type: file[:file_type] || file['file_type'],
          size: file[:size] || file['size'],
          url: file[:url] || file['url']
        }.compact
      end

      def valid_file?(file)
        return false unless file.is_a?(Hash)

        !file[:url].to_s.empty?
      end
    end
  end
end
