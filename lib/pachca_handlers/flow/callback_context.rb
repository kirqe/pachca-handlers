# frozen_string_literal: true

class CallbackContext
  def initialize(context)
    @params = context[:params]
    @handler = context[:handler]
    @step = context[:step]
    @value = context[:value]
    @step_key = context[:step_key]
    @field_key = context[:field_key]
  end

  def [](key)
    case key
    when :params then @params
    when :handler then @handler
    when :step then @step
    when :value then @value
    when :step_key then @step_key
    when :field_key then @field_key
    end
  end

  def go_back_to(step_key, field_key = nil)
    # find first field in step if no specific field is targeted
    unless field_key
      target_step = @handler.class.steps.find { |s| s.key == step_key }
      field_key = find_first_field_key(target_step)
    end

    return :restart unless field_key

    # reset target field
    @handler.session.steps_data_manager.update_field!(step_key, field_key, nil)
    @handler.session.steps_data_manager.update_step!(step_key, :step_completed, false)

    # mark not visited
    field_obj = @handler.session.steps_data_manager.field(step_key, field_key)
    field_obj[:visited] = false if field_obj
    @handler.session.steps_data_manager.save

    :restart
  end

  def set_field(field_key, value)
    @handler.session.steps_data_manager.update_field!(@step_key, field_key, value)
  end

  def get_field_value(step_key, field_key)
    @handler.session.steps_data_manager.field_value(step_key, field_key)
  end

  def complete_step
    @handler.session.steps_data_manager.update_step!(@step_key, :step_completed, true)
  end

  private

  def find_first_field_key(target_step)
    return nil unless target_step&.fields&.any?

    target_step.fields.first.key
  end
end
