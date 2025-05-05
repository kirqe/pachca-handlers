# frozen_string_literal: true

require_relative 'base_handler'
require_relative '../../services/assistant'

class YandexAssistantHandler < BaseHandler
  title 'Yandex Assistant'
  command 'a'
  assistant true

  def perform; end
end
