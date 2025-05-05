# frozen_string_literal: true

require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/pachca_bots.db')
