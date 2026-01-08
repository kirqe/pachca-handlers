# frozen_string_literal: true

require 'cgi'

module PachcaHandlers
  module Flow
    class FieldPrompter
      def initialize(session:, message_service:)
        @session = session
        @message_service = message_service
      end

      def prompt(step:, field:)
        message = field.name
        message += "\n(#{field.description})" if field.description

        buttons = build_buttons(step: step, field: field)
        existing_prompt_id = @session.steps_data_manager.last_prompt_message_id

        if buttons&.any?
          deliver_buttons_prompt(step: step, field: field, message: message, buttons: buttons,
                                 existing_prompt_id: existing_prompt_id)
        else
          deliver_text_prompt(step: step, field: field, message: message, existing_prompt_id: existing_prompt_id)
        end
      end

      private

      def deliver_buttons_prompt(step:, field:, message:, buttons:, existing_prompt_id:)
        prompt_message = I18n.t('messages.field_prompt_buttons', field: message)

        if existing_prompt_id
          @message_service.update_message(existing_prompt_id, content: prompt_message, buttons: buttons)
          @session.steps_data_manager.update_field_prompt_message_id!(step.key, field.key, existing_prompt_id)
          return
        end

        message_id = @message_service.deliver_with_id(prompt_message, buttons)
        @session.steps_data_manager.update_field_prompt_message_id!(step.key, field.key, message_id)
      end

      def deliver_text_prompt(step:, field:, message:, existing_prompt_id:)
        if existing_prompt_id
          confirmation_message = build_confirmation_message(step: step, field: field)
          @message_service.update_message(existing_prompt_id, content: confirmation_message, buttons: [])
        end

        @message_service.deliver(I18n.t('messages.field_prompt', field: message))
      end

      def build_buttons(step:, field:)
        options = field.options
        return nil unless options&.any?

        options.map do |opt|
          [{ text: opt, data: "field:#{@session.command}:#{step.key}:#{field.key}:#{CGI.escape(opt.to_s)}" }]
        end
      end

      def build_confirmation_message(step:, field:)
        previous_value = @session.steps_data_manager.previous_field_value(step, field)
        if previous_value.is_a?(Hash)
          display = previous_value[:name] || previous_value['name'] || previous_value[:key] || previous_value['key']
          return I18n.t('messages.field_selected', value: display) if display
        end
        return I18n.t('messages.field_selected', value: previous_value) if previous_value

        I18n.t('messages.field_completed')
      end
    end
  end
end
