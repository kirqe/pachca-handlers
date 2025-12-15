# frozen_string_literal: true

require_relative '../../../lib/internal/clients/llm_client'

module Summarizer
  MAX_TOKENS = 25_000
  CHUNK_SIZE = 20_000

  def self.summarize_large(text)
    if token_count(text) > MAX_TOKENS
      chunks = chunk_text(text, CHUNK_SIZE)
      partials = chunks.map { |chunk| summarize(chunk) }
      summarize(partials.join("\n\n"))
    else
      summarize(text)
    end
  end

  def self.summarize(text)
    client = LLMClient.new
    response = client.chat_completion(
      [
        { role: 'system', content: 'Ты интеллигентный ассистент, который дает краткое описание текста (summary)' },
        { role: 'user', content: "Суммаризируй этот текст:\n\n#{text}" }
      ]
    )

    response.choices.first.message.content&.strip || ''
  end

  def self.token_count(text)
    (text.length / 4.0).ceil
  end

  def self.chunk_text(text, size)
    words = text.split
    words.each_slice(size).map { |w| w.join(' ') }
  end
end
