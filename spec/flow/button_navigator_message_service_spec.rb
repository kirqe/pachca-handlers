# frozen_string_literal: true

require 'i18n'

require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/flow/button_navigator'
require_relative '../../lib/pachca_handlers/registry/handlers_registry'

RSpec.describe PachcaHandlers::Flow::ButtonNavigator do
  before do
    PachcaHandlers::Registry::HandlersRegistry.instance_variable_set(:@handlers, {})
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, buttons: { back: 'Back' })
    I18n.default_locale = :en
  end

  it 'passes message_service into callback context for button clicks' do
    handler_class = Class.new(PachcaHandlers::Handlers::BaseHandler) do
      title 'Test'
      command 'test'

      step :status do
        field :action do
          name 'Status'
          options ['Check']
          callback do |ctx|
            ctx.send_message('ok')
            nil
          end
        end
      end
    end

    steps_data_manager = instance_double('StepsDataManager', update_field!: true, mark_emitted_output!: true)
    session = instance_double('Session', steps_data_manager: steps_data_manager)
    message_service = instance_double('MessageService', deliver: true)

    navigator = described_class.new(session: session, handler_class: handler_class, message_service: message_service)
    out = navigator.handle_field_click(step_key: :status, field_key: :action, value: 'Check', event_params: {})

    expect(out).to be_nil
  end
end
