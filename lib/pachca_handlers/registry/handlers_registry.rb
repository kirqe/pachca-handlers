# frozen_string_literal: true

class CommandExistsError < StandardError; end

class HandlersRegistry
  @handlers = {}

  def self.register(handler_class, command)
    raise CommandExistsError, "Command #{command} already registered" if @handlers[command]

    @handlers[command] = handler_class
  end

  def self.get(command)
    @handlers[command]
  end

  def self.get_by_matcher(text)
    @handlers.values.find { |handler| handler.match?(text) }
  end

  def self.all
    @handlers
  end
end
