# frozen_string_literal: true

require './config/environment'
require './app'

map '/health' do
  run ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
end

run App.freeze.app
