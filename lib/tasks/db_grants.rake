# S1-G2 · I4 — apply db/grants.sql (table-specific ACLs pg_dump strips from
# structure.sql). Run as the owner (bin/db-migrate db:grants) after every schema load.
namespace :db do
  desc "Apply db/grants.sql (role grants/revokes not captured by structure.sql)"
  task grants: :environment do
    path = Rails.root.join("db/grants.sql")
    next unless path.exist?

    ActiveRecord::Base.connection.execute(path.read)
    puts "db:grants — applied #{path.basename}"
  end
end
