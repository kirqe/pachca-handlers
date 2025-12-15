# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require_relative 'database'
require 'i18n'

require_relative '../lib/pachca_handlers/loader'
PachcaHandlers::Loader.load!

# I18n
I18n.load_path << Dir[File.join(__dir__, './locales.yml')]
I18n.default_locale = ENV.fetch('LOCALE', 'en')
