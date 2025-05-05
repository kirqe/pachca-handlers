# frozen_string_literal: true

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

class StepsDataManager
  def initialize(session)
    @session = session
    @command = @session.command
  end

  def prepare
    steps = handler_class.steps

    @data = { @command => { steps: {} } }
    steps.each do |step|
      @data[@command][:steps][step.key.to_sym] = {
        intro_shown: false,
        step_completed: false,
        skipped: false,
        fields: {}
      }

      step.fields.each do |field|
        @data[@command][:steps][step.key.to_sym][:fields][field.key.to_sym] = {
          visited: false,
          value: nil,
          name: field.name
        }
      end
    end

    @data
  end

  def prepare!
    @data = prepare
    save
  end

  def save
    @session.steps_data = @data.to_json
    @session.save
  end

  def data
    @data ||= JSON.parse(@session.steps_data, symbolize_names: true)
  end

  def handler_class
    @handler_class ||= HandlersRegistry.get(@session.command)
  end

  def next_field
    each_step do |step, step_obj|
      next if step_completed?(step_obj)

      result = process_step(step, step_obj)
      return result if result
    end
    nil
  end

  def process_step(step, step_obj)
    return [step, nil] if step.show_intro? && !step_obj[:intro_shown] && step.fields.empty?

    each_field(step) do |field, field_obj|
      return [step, field] unless field_obj&.dig(:visited)
    end
  end

  def step_completed?(step_obj)
    step_obj[:step_completed] || step_obj[:skipped]
  end

  def field_value(step_key, field_key)
    field_obj = field(step_key, field_key)
    field_obj[:value]
  end

  def field_filled?(step_key, field_key)
    !!field_value(step_key, field_key)
  end

  def update_field!(step_key, field_key, value)
    field_obj = field(step_key, field_key)
    field_obj[:visited] = true
    field_obj[:value] = value
    save
  end

  def update_step!(step_key, field_key, value)
    step_obj = step(step_key)
    step_obj[field_key] = value
    save
  end

  def step(step_key)
    data.dig(@command.to_sym, :steps, step_key.to_sym)
  end

  def field(step_key, field_key)
    step_obj = step(step_key)
    step_obj&.dig(:fields, field_key.to_sym)
  end

  def serialize
    data.map do |command, data|
      {
        command: command,
        steps: data[:steps].map do |step, step_data|
          {
            key: step,
            fields: step_data[:fields].map do |field, field_data|
              {
                key: field,
                value: field_data[:value]
              }
            end
          }
        end
      }
    end
  end

  private

  def each_step
    handler_class.steps.each { |step| yield(step, step(step.key)) }
  end

  def each_field(step)
    step.fields.each { |field| yield(field, field(step.key, field.key)) }
  end
end
