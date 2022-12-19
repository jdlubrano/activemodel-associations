$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'coveralls'
Coveralls.wear!

require 'byebug'
require 'pry-byebug'

require 'activemodel/associations'
require_relative 'db/migrate/10_create_users'
ActiveModel::Associations::Hooks.init

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Test Class
class User < ActiveRecord::Base; end
schema_migration = ActiveRecord::Base.connection.schema_migration
schema_migration.create_table
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.new(:up, [CreateUsers.new], schema_migration).migrate

require 'database_cleaner'

RSpec.configure do |config|
  config.order = :random

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
