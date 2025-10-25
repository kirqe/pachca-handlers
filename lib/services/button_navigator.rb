# frozen_string_literal: true

require 'cgi'
require_relative '../internal/handlers_registry'

class ButtonNavigator
  def initialize(session:, handler_class:, message_service:)
    @session = session
    @handler_class = handler_class
    @message_service = message_service
  end

  def parse_payload(data)
    verb, command, step_key, field_key, value = data.split(':', 5)
    [verb, command, step_key.to_sym, field_key.to_sym, CGI.unescape(value.to_s)]
  end

  def handle_field_click(step_key:, field_key:, value:, event_params:)
    step = find_step(step_key)
    return unless step

    field = find_field(step, field_key)
    return unless field

    return go_back_to(field.go_back_target) if value == I18n.t('buttons.back') && field.go_back_target

    out = field.evaluated_field(:callback, {
                                  params: event_params,
                                  handler: @handler_class.new(session: @session, params: event_params),
                                  step: step,
                                  value: value,
                                  step_key: step.key,
                                  field_key: field.key
                                })

    # we didn't go back
    @session.steps_data_manager.update_field!(step.key, field.key, value) if out != :restart

    out
  end

  def go_back_to(step_key, field_key = nil)
    unless field_key
      target_step = @handler_class.steps.find { |s| s.key == step_key }
      return :restart unless target_step

      field_key = target_step.fields.first.key
    end

    # reset field
    @session.steps_data_manager.update_field!(step_key, field_key, nil)
    @session.steps_data_manager.update_step!(step_key, :step_completed, false)

    # mark field as not visited
    field_obj = @session.steps_data_manager.field(step_key, field_key)
    field_obj[:visited] = false if field_obj
    @session.steps_data_manager.save

    :restart
  end

  private

  def find_step(step_key)
    @handler_class.steps.find { |s| s.key.to_sym == step_key }
  end

  def find_field(step, field_key)
    step.fields.find { |f| f.key.to_sym == field_key }
  end
end
