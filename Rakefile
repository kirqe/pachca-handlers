# frozen_string_literal: true

require './config/environment'
require 'sequel'

Sequel.extension :migration

namespace :db do
  desc 'Run migrations'
  task :migrate do
    Sequel::Migrator.run(DB, 'db/migrations')
  end

  desc 'Rollback migrations'
  task :rollback, [:version] do |_t, args|
    version = args[:version] ? args[:version].to_i : 1
    Sequel::Migrator.run(DB, 'db/migrations', target: version)
  end
end
