# frozen_string_literal: true

require 'json'

module PachcaHandlers
  module Flow
    class StepsData
      attr_reader :command_key, :data

      def initialize(command_key:, data:)
        @command_key = command_key
        @data = data
      end

      def self.build(command_key:, handler_class:)
        data = { command_key => { steps: {}, emitted_output: false } }

        handler_class.steps.each do |step|
          data[command_key][:steps][step.key.to_sym] = {
            intro_shown: false,
            step_completed: false,
            skipped: false,
            fields: {}
          }

          step.fields.each do |field|
            data[command_key][:steps][step.key.to_sym][:fields][field.key.to_sym] = {
              visited: false,
              value: nil,
              name: field.name,
              prompt_message_id: nil
            }
          end
        end

        new(command_key: command_key, data: data)
      end

      def self.parse(json, command_key:)
        data = JSON.parse(json.to_s, symbolize_names: true)
        data[command_key] ||= { steps: {}, emitted_output: false }
        new(command_key: command_key, data: data)
      rescue JSON::ParserError
        new(command_key: command_key, data: { command_key => { steps: {}, emitted_output: false } })
      end

      def to_json(*)
        @data.to_json(*)
      end

      def next_field(handler_class:, skip_step: nil)
        handler_class.steps.each do |step|
          next if skip_step&.call(step)

          step_obj = step(step.key)
          next if step_completed?(step_obj)

          result = process_step(step, step_obj)
          return result if result
        end
        nil
      end

      def field_filled?(step_key, field_key)
        field_obj = field(step_key, field_key)
        field_obj&.dig(:visited) && !field_obj[:value].nil?
      end

      def field_value(step_key, field_key)
        field(step_key, field_key)&.dig(:value)
      end

      def update_field!(step_key, field_key, value)
        field_obj = field(step_key, field_key)
        return unless field_obj

        field_obj[:visited] = true
        field_obj[:value] = value
      end

      def reset_field!(step_key, field_key)
        step_obj = step(step_key)
        return unless step_obj

        field_obj = step_obj.dig(:fields, field_key.to_sym)
        return unless field_obj

        step_obj[:step_completed] = false
        field_obj[:visited] = false
        field_obj[:value] = nil
      end

      def go_back_to(handler_class:, step_key:, field_key: nil)
        field_key ||= first_field_key(handler_class: handler_class, step_key: step_key)
        return :restart unless field_key

        reset_field!(step_key, field_key)
        :restart
      end

      def update_step!(step_key, field_key, value)
        step_obj = step(step_key)
        return unless step_obj

        step_obj[field_key] = value
      end

      def step(step_key)
        @data.dig(@command_key, :steps, step_key.to_sym)
      end

      def field(step_key, field_key)
        step_obj = step(step_key)
        step_obj&.dig(:fields, field_key.to_sym)
      end

      def update_field_prompt_message_id!(step_key, field_key, message_id)
        field_obj = field(step_key, field_key)
        return unless field_obj

        field_obj[:prompt_message_id] = message_id
      end

      def field_prompt_message_id(step_key, field_key)
        field(step_key, field_key)&.dig(:prompt_message_id)
      end

      def move_prompt_message_id!(from_step_key, from_field_key, to_step_key, to_field_key)
        id = field_prompt_message_id(from_step_key, from_field_key)
        return unless id

        update_field_prompt_message_id!(to_step_key, to_field_key, id)
        update_field_prompt_message_id!(from_step_key, from_field_key, nil)
      end

      def serialize
        @data.map do |command, command_data|
          {
            command: command,
            steps: command_data[:steps].map do |step_key, step_data|
              {
                key: step_key,
                fields: step_data[:fields].map do |field_key, field_data|
                  {
                    key: field_key,
                    value: field_data[:value]
                  }
                end
              }
            end
          }
        end
      end

      def mark_emitted_output!
        @data[@command_key][:emitted_output] = true
      end

      def emitted_output?
        !!@data[@command_key][:emitted_output]
      end

      def last_prompt_message_id
        last_seen = nil
        @data[@command_key][:steps].each_value do |step_data|
          step_data[:fields].each_value do |field_data|
            last_seen = field_data[:prompt_message_id] if field_data[:prompt_message_id]
          end
        end
        last_seen
      end

      def previous_field_value(handler_class:, current_step:, current_field:)
        current_step_index = handler_class.steps.find_index { |s| s.key == current_step.key }
        return nil unless current_step_index

        (0...current_step_index).reverse_each do |i|
          step = handler_class.steps[i]
          value = last_completed_field_value(step)
          return value if value
        end

        last_completed_field_value(current_step, current_field)
      end

      private

      def process_step(step, step_obj)
        return [step, nil] if step.show_intro? && !step_obj[:intro_shown] && step.fields.empty?

        step.fields.each do |field|
          field_obj = field(step.key, field.key)
          return [step, field] unless field_obj&.dig(:visited)
        end

        nil
      end

      def step_completed?(step_obj)
        return true if step_obj.nil?

        step_obj[:step_completed] || step_obj[:skipped]
      end

      def first_field_key(handler_class:, step_key:)
        target_step = handler_class.steps.find { |s| s.key == step_key }
        return nil unless target_step&.fields&.any?

        target_step.fields.first.key
      end

      def last_completed_field_value(step, exclude_field = nil)
        step.fields.reverse_each do |field|
          next if exclude_field && field.key == exclude_field.key

          value = field_value(step.key, field.key)
          return value if value && field_filled?(step.key, field.key)
        end
        nil
      end
    end
  end
end
