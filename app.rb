# frozen_string_literal: true

require 'roda'

require_relative 'lib/middleware/signature_check_middleware'
require_relative 'lib/pachca_handlers/webhook/endpoint'

class App < Roda
  use SignatureCheckMiddleware

  plugin :default_headers,
         'Strict-Transport-Security' => 'max-age=63072000; includeSubDomains'
  plugin :common_logger, $stderr
  plugin :halt
  plugin :json
  plugin :json_parser
  plugin :error_handler do |e|
    $stderr.print "#{e.class}: #{e.message}\n"
    warn e.backtrace.join("\n")
  end

  route do |r|
    r.on 'api' do
      r.on 'v1' do
        r.on 'webhook' do
          r.post do
            PachcaHandlers::Webhook::Endpoint.new.call(r.params)

            r.halt 204
          end
        end
      end
    end
  end
end
