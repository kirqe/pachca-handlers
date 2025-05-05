# frozen_string_literal: true

require_relative '../handlers_registry'
require_relative '../field'
require_relative '../result'
require_relative '../step'

class BaseHandler
  attr_accessor :params, :session

  class << self
    def title(value = nil)
      return @title unless value

      @title = value
    end

    def command(value = nil)
      return @command unless value

      @command = value
      HandlersRegistry.register(self, value)
    end

    def steps
      @steps ||= []
    end

    def no_steps?
      steps.nil? || steps.empty?
    end

    def step(key, &)
      step = Step.new(key: key)
      step.instance_eval(&) if block_given?
      steps << step
    end

    def assistant(value = nil)
      return @assistant unless value

      @assistant = value || false
    end

    def assistant?
      !!@assistant
    end
  end

  def initialize(session: nil, params: {})
    @session = session
    @params = params
  end

  def perform
    raise NotImplementedError
  end

  protected

  def field_value(step_key, field_key)
    session.steps_data_manager.field_value(step_key, field_key)
  end

  def serialize_steps_data
    session.steps_data_manager.serialize
  end
end
