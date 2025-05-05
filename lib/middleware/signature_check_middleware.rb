# frozen_string_literal: true

# https://crm.pachca.com/dev/getting-started/webhooks/#securing

class SignatureCheckMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    unauthorized = [401, { 'Content-Type' => 'text/plain' }, ['Unauthorized']]

    return unauthorized if env['HTTP_X_REAL_IP'] != ENV['PACHCA_WH_IP']

    received_signature = env['HTTP_PACHCA_SIGNATURE']
    expected_signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      ENV.fetch('PACHCA_SIGN_SECRET', nil),
      env['rack.input'].read
    )

    return unauthorized if received_signature != expected_signature

    env['rack.input'].rewind

    @app.call(env)
  end
end
