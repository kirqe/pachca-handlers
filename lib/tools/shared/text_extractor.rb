# frozen_string_literal: true

require 'nokogiri'

module TextExtractor
  def self.strip_html(html)
    doc = Nokogiri::HTML(html)
    doc.search('script, style, nav, footer, aside, noscript, header, iframe').remove
    doc.at('body')&.text.to_s.gsub(/\s+/, ' ').strip
  end
end
