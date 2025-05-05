# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require_relative 'database'
require 'i18n'

%w[
  ./lib/internal/handlers/*.rb
  ./lib/internal/tools/*.rb
  ./lib/handlers/*.rb
  ./lib/tools/*.rb
].each { |path| Dir[path].each { |file| require file } }

# I18n
I18n.load_path << Dir[File.join(__dir__, './locales.yml')]
I18n.default_locale = ENV.fetch('LOCALE', 'en')
