# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/internal/handlers/base_handler'

RSpec.describe BaseHandler do
  let(:handler) { BaseHandler.new }

  echo_handler = Class.new(BaseHandler) do
    title 'Echo'
    command 'echo'

    step :step1 do
      field :message do
        name 'Message'
        description 'The message to echo back'
        validations [
          ->(value) { [!value.empty?, 'Message cannot be empty'] },
          ->(value) { [value.length <= 3, 'Message cannot be longer than 3 characters'] }
        ]
        callback { 'Field callback' }
      end
    end

    def perform
      message = field_value(:step1, :message)
      Result.success("Echo: #{message}")
    end
  end

  let(:handler) { echo_handler.new }
  let(:session) { instance_double('session', steps_data_manager: instance_double('steps_data_manager')) }

  before do
    handler.session = session
  end

  describe 'attributes' do
    it 'returns the command' do
      expect(echo_handler.command).to eq('echo')
    end

    it 'returns the steps' do
      expect(echo_handler.steps.count).to eq(1)
      expect(echo_handler.steps.first.key).to eq(:step1)
    end
  end

  describe 'fields' do
    it 'does basic validation' do
      field = echo_handler.steps.first.fields.first
      field.validate('')
      expect(field.valid?).to be_falsey

      field.validate('Hii')
      expect(field.valid?).to be_truthy
    end

    it 'calls callback' do
      field = echo_handler.steps.first.fields.first
      field.validate('Hii')
      expect(field.valid?).to be_truthy

      expect(field.callback.call(handler)).to eq('Field callback')
    end
  end

  describe 'perform' do
    it 'returns the result' do
      allow(handler).to receive(:field_value).with(:step1, :message).and_return('Hii')

      result = handler.perform
      expect(result.success?).to be_truthy
      expect(result.to_s).to eq('Echo: Hii')
    end
  end
end
