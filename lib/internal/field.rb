# frozen_string_literal: true

require_relative 'evaluated_field'

class Field
  include EvaluatedField

  attr_reader :key, :options, :errors

  def initialize(key:)
    @key = key
    @validations = []
    @errors = []
  end

  def name(value = nil)
    return @name unless value

    @name = value
  end

  def description(value = nil)
    return @description unless value

    @description = value
  end

  def validations(value = nil)
    return @validations unless value

    @validations = value
  end

  def callback(proc = nil, &block)
    return @callback unless proc || block_given?

    @callback = proc || block
  end

  def validate(value)
    @errors = []

    @validations.each do |validation|
      result = validation.call(value)
      if result.is_a?(Array)
        valid, message = result
        @errors << message unless valid
      else
        @errors << 'Failed to validate' unless result
      end
    end

    @errors
  end

  def add_validation(validation)
    @validations << validation
    self
  end

  def valid?
    @errors.empty?
  end
end

# TODO: Add options with buttons mb?
# class HandlerField::ValueOption
#   def initialize(key:, name:, value:)
#     @key = key
#     @name = name
#     @value = value
#   end
# end
