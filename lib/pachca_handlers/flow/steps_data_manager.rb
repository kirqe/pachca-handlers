# frozen_string_literal: true

require_relative '../registry/handlers_registry'
require_relative 'steps_data'

#
# steps_data in session
#
# {
#   create_profile_command: {
#     steps: {
#       create_profile: {
#         step_completed: false,
#         skipped: false,
#         intro_shown: false,
#         fields: {
#           name: { visited: false, value: nil },
#           email: { visited: false, value: nil },
#           password: { visited: false, value: nil },
#         }
#       }
#       send_thank_you_message_to_chat: {
#         intro_shown: false,
#         step_completed: false,
#         skipped: false,
#         fields: {}
#       }
#     }
#   }
# }
#
# serialized
#
# [
#   {
#     command: 'create_profile_command',
#     steps: [
#       {
#         key: 'create_profile',
#         fields: [
#           { key: 'name', value: nil },
#           { key: 'email', value: nil },
#           { key: 'password', value: nil }
#         ]
#       }
#     ]
#   }
# ]

module PachcaHandlers
  module Flow
    class StepsDataManager
      def initialize(session)
        @session = session
        @command = @session.command
        @command_key = @command.to_sym
      end

      def prepare
        @steps_data = PachcaHandlers::Flow::StepsData.build(command_key: @command_key, handler_class: handler_class)
        @steps_data.data
      end

      def prepare!
        prepare
        save
      end

      def save
        @session.steps_data = steps_data.to_json
        @session.save
      end

      def data
        steps_data.data
      end

      def handler_class
        @handler_class ||= PachcaHandlers::Registry::HandlersRegistry.get(@session.command)
      end

      def next_field
        steps_data.next_field(handler_class: handler_class, skip_step: method(:skip_step?))
      end

      def field_filled?(step_key, field_key)
        steps_data.field_filled?(step_key, field_key)
      end

      def field_value(step_key, field_key)
        steps_data.field_value(step_key, field_key)
      end

      def update_field!(step_key, field_key, value)
        steps_data.update_field!(step_key, field_key, value)
        save
      end

      def reset_field!(step_key, field_key)
        steps_data.reset_field!(step_key, field_key)
        save
      end

      def go_back_to(step_key, field_key = nil)
        result = steps_data.go_back_to(handler_class: handler_class, step_key: step_key, field_key: field_key)
        save
        result
      end

      def update_step!(step_key, field_key, value)
        steps_data.update_step!(step_key, field_key, value)
        save
      end

      def step(step_key)
        steps_data.step(step_key)
      end

      def field(step_key, field_key)
        steps_data.field(step_key, field_key)
      end

      def update_field_prompt_message_id!(step_key, field_key, message_id)
        steps_data.update_field_prompt_message_id!(step_key, field_key, message_id)
        save
      end

      def field_prompt_message_id(step_key, field_key)
        steps_data.field_prompt_message_id(step_key, field_key)
      end

      def move_prompt_message_id!(from_step_key, from_field_key, to_step_key, to_field_key)
        steps_data.move_prompt_message_id!(from_step_key, from_field_key, to_step_key, to_field_key)
        save
      end

      def serialize
        steps_data.serialize
      end

      def mark_emitted_output!
        steps_data.mark_emitted_output!
        save
      end

      def emitted_output?
        steps_data.emitted_output?
      end

      def last_prompt_message_id
        steps_data.last_prompt_message_id
      end

      def previous_field_value(current_step, current_field)
        steps_data.previous_field_value(handler_class: handler_class, current_step: current_step,
                                        current_field: current_field)
      end

      def skip_step?(step)
        predicate = step.skip_if
        return false unless predicate

        ctx = { params: {}, handler: handler_instance, step: step }
        !!step.evaluated_field(:skip_if, ctx)
      end

      private

      def steps_data
        @steps_data ||= PachcaHandlers::Flow::StepsData.parse(@session.steps_data, command_key: @command_key)
      end

      def handler_instance
        @handler_instance ||= handler_class.new(session: @session, params: {})
      end
    end
  end
end
