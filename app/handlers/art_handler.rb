# frozen_string_literal: true

require 'stringio'

require_relative '../../lib/pachca_handlers/handlers/base_handler'
require_relative '../../lib/pachca_handlers/integrations/yandex_art_client'

class ArtHandler < PachcaHandlers::Handlers::BaseHandler
  title 'Generate Image (YandexART)'
  command 'art'

  step :prompt do
    intro 'Describe the image you want to generate'

    field :prompt do
      name 'Prompt'
      description 'Example: “a minimal flat icon of a coffee cup, white background”'

      validations [
        ->(value) { [!value.to_s.strip.empty?, 'Prompt cannot be empty'] }
      ]

      callback { |ctx| start_generation(ctx) }
    end
  end

  step :status do
    intro 'When the image is ready, it will be sent as an attachment'

    field :action do
      name 'Status'
      options ['Check status']

      callback { |ctx| check_generation(ctx) }
    end
  end

  private

  def start_generation(ctx)
    operation_id = yandex_client.generate_async(prompt: ctx[:value].to_s)

    ctx.set_step_value(:prompt, :operation_id, operation_id.to_s)
    "Generating…\nOperation id: #{operation_id}\nUse “Check status” to fetch the result."
  rescue PachcaHandlers::Integrations::YandexArtClient::Error => e
    ctx.reset_field(:prompt, :prompt)
    PachcaHandlers::Result.error("YandexART error: #{e.message}")
  end

  def check_generation(ctx)
    operation_id = ctx.get_step_value(:prompt, :operation_id).to_s
    return reset_check(ctx, PachcaHandlers::Result.error('Missing operation id (restart /art)')) if operation_id.empty?

    bytes = yandex_client.fetch_image_bytes(operation_id)
    if bytes.nil?
      ctx.send_message('Still generating. Try again in a bit.')
      return :restart
    end

    send_image(ctx, bytes)
  rescue PachcaHandlers::Integrations::YandexArtClient::Error => e
    reset_check(ctx, PachcaHandlers::Result.error("YandexART error: #{e.message}"))
  end

  def reset_check(ctx, output)
    ctx.reset_field(:status, :action)
    output
  end

  def yandex_client
    @yandex_client ||= PachcaHandlers::Integrations::YandexArtClient.new
  end

  def send_image(ctx, bytes)
    uploaded = ctx.upload_file(
      StringIO.new(bytes),
      filename: 'yandex_art.jpeg',
      file_type: 'image',
      content_type: 'image/jpeg'
    )

    ctx.send_message('Generated image:', files: [uploaded])
    nil
  end
end
