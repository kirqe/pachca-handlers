# frozen_string_literal: true

require_relative 'field'
require_relative 'evaluated_field'

class Step
  include EvaluatedField

  attr_reader :key, :fields

  def initialize(key: nil)
    @key = key
    @fields = []
  end

  def intro(text = nil)
    return @intro unless text

    @intro = text.is_a?(Proc) ? text : -> { text }
  end

  def callback(proc = nil, &block)
    return @callback unless proc || block_given?

    @callback = proc || block
  end

  def field(key, &)
    f = Field.new(key: key)
    f.instance_eval(&)
    fields << f
  end

  def show_intro?
    !!@intro
  end

  def complete?(session)
    fields.all? { |f| session.steps_data_manager.field_filled?(key, f.key) }
  end
end
