# frozen_string_literal: true

class SessionFlow
  def initialize(event:, session_service:, message_service:)
    @event = event
    @session_service = session_service
    @message_service = message_service
  end

  def start
    return unless session

    loop do
      step, field = session.steps_data_manager.next_field
      return complete_session unless step

      if step.show_intro? && !intro_shown?(step)
        show_intro(step)

        if step.fields.empty?
          complete_step(step)
          next
        end
      end

      field ? prompt_field(field) : complete_step(step)
      break
    end
  end

  def continue
    return unless session

    step, field = session.steps_data_manager.next_field
    return complete_session unless step

    if field
      field.validate(@event.content)
      if field.valid?
        fill_field(step, field)

        complete_step(step) if step.complete?(session)
        start
      else
        @message_service.deliver(I18n.t('messages.invalid_input', error: field.errors.join(', ')))
      end
    else
      complete_step(step)
      start
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

  def prompt_field(field)
    message = field.name
    message += "\n(#{field.description})" if field.description
    @message_service.deliver(I18n.t('messages.field_prompt', field: message))
  end

  def fill_field(step, field)
    value = @event.content
    session.steps_data_manager.update_field!(step.key, field.key, value)
    field.evaluated_field(:callback, { params: @event.params,
                                       handler: handler,
                                       step: step })
  end

  def complete_step(step)
    session.steps_data_manager.update_step!(step.key, :step_completed, true)
    step.evaluated_field(:callback, { params: @event.params,
                                      handler: handler,
                                      step: step })
  end

  def complete_session
    result = handler.perform
    @message_service.post_result(result) if result
    session.complete!
  end

  def handler
    @handler ||= session.steps_data_manager.handler_class.new(session: session, params: @event.params)
  end
end
