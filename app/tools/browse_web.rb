# frozen_string_literal: true

require_relative '../../lib/pachca_handlers/assistant/base_tool'
require_relative '../../lib/pachca_handlers/integrations/base_client'
require_relative 'shared/summarizer'
require_relative 'shared/text_extractor'

class BrowseWeb < PachcaHandlers::Assistant::BaseTool
  required :url, String, doc: 'URL to browse'
  required :summarize, OpenAI::Boolean, default: false, doc: 'Summarize the content'

  def self.call(url:, summarize: false, runtime_context: {})
    _ = runtime_context

    response = PachcaHandlers::Integrations::BaseClient.get(url)
    return PachcaHandlers::Result.error([I18n.t('messages.something_went_wrong')]) unless response.success?

    return PachcaHandlers::Result.success(response.body) unless summarize

    content = TextExtractor.strip_html(response.body)
    summary = Summarizer.summarize_large(content)
    PachcaHandlers::Result.success(summary)
  end
end
