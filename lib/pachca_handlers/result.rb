# frozen_string_literal: true

module PachcaHandlers
  class Result
    attr_reader :data, :success, :errors

    def initialize(data, success: true, errors: [])
      @data = data
      @success = success
      @errors = errors
    end

    def success?
      @success
    end

    def errors?
      @errors.any?
    end

    def to_s
      errors? ? @errors.join(', ') : @data.to_s
    end

    def self.success(data)
      new(data, success: true, errors: [])
    end

    def self.error(errors)
      errors = [errors] unless errors.is_a?(Array)
      new(nil, success: false, errors: errors)
    end
  end
end
