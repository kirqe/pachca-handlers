# frozen_string_literal: true

require_relative '../integrations/file_downloader'

module PachcaHandlers
  module Flow
    class CallbackContext
      def initialize(context)
        @params = context[:params]
        @handler = context[:handler]
        @message_service = context[:message_service]
        @step = context[:step]
        @value = context[:value]
        @step_key = context[:step_key]
        @field_key = context[:field_key]
      end

      def [](key)
        case key
        when :params then @params
        when :handler then @handler
        when :message_service then @message_service
        when :step then @step
        when :value then @value
        when :step_key then @step_key
        when :field_key then @field_key
        end
      end

      def go_back_to(step_key, field_key = nil)
        @handler.session.steps_data_manager.go_back_to(step_key, field_key)
      end

      def set_field(field_key, value)
        @handler.session.steps_data_manager.update_field!(@step_key, field_key, value)
        nil
      end

      def get_field_value(step_key, field_key)
        @handler.session.steps_data_manager.field_value(step_key, field_key)
      end

      def set_step_value(step_key, key, value)
        @handler.session.steps_data_manager.update_step!(step_key, key, value)
        nil
      end

      def get_step_value(step_key, key)
        step = @handler.session.steps_data_manager.step(step_key)
        return nil unless step

        step[key.to_sym]
      end

      def skip_step(step_key = @step_key)
        @handler.session.steps_data_manager.update_step!(step_key, :skipped, true)
        nil
      end

      def unskip_step(step_key = @step_key)
        @handler.session.steps_data_manager.update_step!(step_key, :skipped, false)
        nil
      end

      def reset_field(step_key, field_key)
        @handler.session.steps_data_manager.reset_field!(step_key, field_key)
        nil
      end

      def complete_step
        @handler.session.steps_data_manager.update_step!(@step_key, :step_completed, true)
        nil
      end

      def download_file(
        file_or_url,
        max_bytes: PachcaHandlers::Integrations::FileDownloader::DEFAULT_MAX_BYTES,
        headers: {}
      )
        url = file_or_url
        filename = nil

        if file_or_url.is_a?(Hash)
          url = file_or_url[:url] || file_or_url['url']
          filename = file_or_url[:name] || file_or_url['name']
        end

        raise ArgumentError, 'File url is required' if url.to_s.empty?

        PachcaHandlers::Integrations::FileDownloader.download(
          url,
          max_bytes: max_bytes,
          filename: filename,
          headers: headers
        )
      end

      def send_message(content, buttons: [], files: [])
        raise 'message_service is required' unless @message_service

        @message_service.deliver(content, buttons, files: files)
        @handler.session.steps_data_manager.mark_emitted_output!
        nil
      end

      def upload_file(file_io, filename:, file_type: 'file', content_type: nil)
        PachcaHandlers::Integrations::PachcaClient.new.upload_file(
          file_io,
          filename: filename,
          file_type: file_type,
          content_type: content_type
        )
      end
    end
  end
end
