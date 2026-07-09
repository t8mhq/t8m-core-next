# S1-G1 · I5 — RLS schema lint (annex §5). Fails CI when any table with a
# tenant_id/seller_tenant_id column lacks ENABLE+FORCE RLS, or when an RLS-enabled
# table has zero policies. Names the table and the missing piece.
namespace :lint do
  desc "Fail when a tenant-scoped table lacks ENABLE+FORCE RLS or a policy (S1-G1 I5)"
  task rls_schema: :environment do
    conn = ActiveRecord::Base.connection
    problems = []

    conn.exec_query(<<~SQL).each do |r|
      SELECT DISTINCT c.relname AS tbl, c.relrowsecurity AS enabled, c.relforcerowsecurity AS forced
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
      JOIN pg_attribute a ON a.attrelid = c.oid
        AND a.attname IN ('tenant_id', 'seller_tenant_id') AND NOT a.attisdropped
      WHERE c.relkind = 'r' AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity)
      ORDER BY 1
    SQL
      missing = []
      missing << "ENABLE" unless r["enabled"]
      missing << "FORCE" unless r["forced"]
      problems << "#{r['tbl']}: has a tenant/seller_tenant column but is missing #{missing.join(' + ')} ROW LEVEL SECURITY"
    end

    conn.exec_query(<<~SQL).each do |r|
      SELECT c.relname AS tbl
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
      WHERE c.relkind = 'r' AND c.relrowsecurity
        AND NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid)
      ORDER BY 1
    SQL
      problems << "#{r['tbl']}: RLS is enabled but the table has zero policies"
    end

    if problems.empty?
      puts "rls schema lint: OK — every tenant-scoped table has ENABLE+FORCE RLS and a policy"
    else
      warn "rls schema lint: #{problems.size} problem(s):\n"
      problems.each { |p| warn "  #{p}" }
      abort "rls schema lint failed"
    end
  end
end
