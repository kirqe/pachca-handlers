# frozen_string_literal: true

require 'cgi'

class SessionFlow
  def initialize(event:, session_service:, message_service:)
    @event = event
    @session_service = session_service
    @message_service = message_service
  end

  def start
    return unless session

    result = session.steps_data_manager.next_field

    unless result
      handle_no_more_fields
      return complete_session
    end

    step, field = result
    return complete_session unless step

    @current_step = step
    handle_step_with_fields(step, field)
  end

  def handle_no_more_fields
    handler_class = HandlersRegistry.get(session.command)
    handler_class.steps.each do |step|
      step_obj = session.steps_data_manager.step(step.key)
      next if step_obj[:step_completed] || step_obj[:skipped]
      next unless step.fields.empty?

      complete_step(step)
    end
  end

  def handle_step_with_fields(step, field)
    show_intro_if_needed(step)

    if step.fields.empty?
      complete_step(step)
    else
      field ? prompt_field(step, field) : complete_step(step)
    end
  end

  def show_intro_if_needed(step)
    return unless step.show_intro? && !intro_shown?(step)

    existing_prompt_id = find_last_prompt_message_id
    show_intro(step) unless existing_prompt_id
  end

  def continue
    return unless session

    result = session.steps_data_manager.next_field
    return complete_session unless result

    step, field = result
    return complete_session unless step

    field ? handle_field_input(step, field) : handle_step_without_field(step)
  end

  def handle_field_input(step, field)
    field.validate(@event.content)
    if field.valid?
      fill_field(step, field)
      complete_step(step) if step.complete?(session)
      start
    else
      @message_service.deliver(I18n.t('messages.invalid_input', error: field.errors.join(', ')))
    end
  end

  def handle_step_without_field(step)
    complete_step(step)
    start
  end

  def complete_step(step)
    session.steps_data_manager.update_step!(step.key, :step_completed, true)
    out = step.evaluated_field(:callback, { params: @event.params,
                                            handler: handler,
                                            step: step })
    deliver_callback_output(out)
  end

  def deliver_callback_output(out)
    case out
    when Result
      @message_service.post_result(out)
      session.steps_data_manager.mark_emitted_output!
    when String
      @message_service.deliver(out)
      session.steps_data_manager.mark_emitted_output!
    when Array
      out.each { |m| deliver_callback_output(m) }
    when Symbol
      if out == :restart
        session.steps_data_manager.mark_emitted_output!
        # restart the flow instead of completing the session
        start
      end
    when nil
      # no-op
    end
  end

  private

  def session
    @session ||= @session_service.find_session
  end

  def show_intro(step)
    intro = step.evaluated_field(:intro, { params: @event.params,
                                           handler: handler,
                                           step: step })
    @message_service.deliver(I18n.t('messages.step_intro', message: intro))
    session.steps_data_manager.update_step!(step.key, :intro_shown, true)
  end

  def intro_shown?(step)
    step_obj = session.steps_data_manager.step(step.key)
    step_obj[:intro_shown]
  end

  def prompt_field(step, field)
    message = field.name
    message += "\n(#{field.description})" if field.description
    buttons = build_buttons_for_field(field)
    existing_prompt_id = find_last_prompt_message_id

    if buttons && !buttons.empty?
      # button-specific message
      prompt_message = I18n.t('messages.field_prompt_buttons', field: message)
      if existing_prompt_id
        # update existing message in-place
        @message_service.update_message(existing_prompt_id, content: prompt_message, buttons: buttons)
        # move the prompt id to this field
        session.steps_data_manager.update_field_prompt_message_id!(step.key, field.key, existing_prompt_id)
      else
        # create new message
        message_id = @message_service.deliver_with_id(prompt_message, buttons)
        session.steps_data_manager.update_field_prompt_message_id!(step.key, field.key, message_id)
      end
    else
      # field has no buttons - create new message
      if existing_prompt_id
        # clear buttons and show confirmation of previous selection
        confirmation_message = build_confirmation_message(step, field)
        @message_service.update_message(existing_prompt_id, content: confirmation_message, buttons: [])
      end

      # post new message for text input
      @message_service.deliver(I18n.t('messages.field_prompt', field: message))
    end
  end

  def fill_field(step, field)
    value = @event.content
    session.steps_data_manager.update_field!(step.key, field.key, value)
    out = field.evaluated_field(:callback, { params: @event.params,
                                             handler: handler,
                                             step: step,
                                             value: value,
                                             step_key: step.key,
                                             field_key: field.key })
    deliver_callback_output(out)
  end

  def complete_session
    unless session.steps_data_manager.emitted_output?
      result = handler.perform
      @message_service.post_result(result) if result
    end
    session.complete!
  end

  def handler
    @handler ||= session.steps_data_manager.handler_class.new(session: session, params: @event.params)
  end

  def build_buttons_for_field(field)
    options = field.options
    return nil unless options && !options.empty?

    # cached current step to avoid multiple next_field calls
    return nil unless @current_step

    options.map do |opt|
      [{ text: opt, data: "field:#{session.command}:#{@current_step.key}:#{field.key}:#{CGI.escape(opt.to_s)}" }]
    end
  end

  def find_last_prompt_message_id
    # most recent field that has a prompt_message_id
    session.steps_data_manager.data[session.command.to_sym][:steps].each_value do |step_data|
      step_data[:fields].each_value do |field_data|
        return field_data[:prompt_message_id] if field_data[:prompt_message_id]
      end
    end
    nil
  end

  def get_previous_field_value(current_step, current_field)
    # most recently completed field value
    handler_class = HandlersRegistry.get(session.command)

    # check previous steps first
    current_step_index = handler_class.steps.find_index { |s| s.key == current_step.key }
    return nil unless current_step_index

    # look backwards through steps and fields
    (0...current_step_index).reverse_each do |i|
      step = handler_class.steps[i]
      value = find_last_completed_field_value(step)
      return value if value
    end

    # check current step for previous fields
    find_last_completed_field_value(current_step, current_field)
  end

  def find_last_completed_field_value(step, exclude_field = nil)
    step.fields.reverse_each do |field|
      next if exclude_field && field.key == exclude_field.key

      value = session.steps_data_manager.field_value(step.key, field.key)
      return value if value && session.steps_data_manager.field_filled?(step.key, field.key)
    end
    nil
  end

  def build_confirmation_message(step, field)
    previous_value = get_previous_field_value(step, field)
    return I18n.t('messages.field_selected', value: previous_value) if previous_value

    I18n.t('messages.field_completed')
  end
end
