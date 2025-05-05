# frozen_string_literal: true

class InlineParams
  def initialize(text)
    @text = text
  end

  def parse
    return {} if @text.to_s.strip.empty?

    _, arg_text = @text.strip.split(/\s+/, 2)
    return {} unless arg_text

    params = extract_inline_params(arg_text)
    return { message: arg_text } if params.empty? && !arg_text.strip.empty?

    params
  end

  private

  def extract_inline_params(text)
    text.scan(/(\w+)=(".*?"|\S+)/)
        .to_h
        .transform_keys(&:to_sym)
        .transform_values { |v| v.gsub(/\A"|"\Z/, '') } # strip surrounding quotes
  end
end
