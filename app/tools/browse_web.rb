# frozen_string_literal: true

require_relative '../../lib/internal/tools/base_tool'
require_relative '../../lib/internal/clients/base_client'
require_relative 'shared/summarizer'
require_relative 'shared/text_extractor'

class BrowseWeb < BaseTool
  required :url, String, doc: 'URL to browse'
  required :summarize, OpenAI::Boolean, default: false, doc: 'Summarize the content'

  def self.call(url:, summarize: false, runtime_context: {})
    _ = runtime_context

    response = BaseClient.get(url)
    return Result.error([I18n.t('messages.something_went_wrong')]) unless response.success?

    return Result.success(response.body) unless summarize

    content = TextExtractor.strip_html(response.body)
    summary = Summarizer.summarize_large(content)
    Result.success(summary)
  end
end
