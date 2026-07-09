# S1-G1 · I1.3 / D2 — one shared definition of the tenant-scoped table template.
#
# `include Rls::MigrationHelpers` in a migration, then `enable_tenant_rls :table`.
# Emits ENABLE + FORCE RLS (D2: both, always) and the `tenant_isolation` policy
# (annex §2). A policy without `FOR` covers all commands and WITH CHECK defaults to
# USING, so INSERT/UPDATE row values are also constrained to the session tenant.
module Rls
  module MigrationHelpers
    def enable_tenant_rls(table, column: :tenant_id)
      reversible do |dir|
        dir.up do
          execute <<~SQL
            ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY;
            ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;
            CREATE POLICY tenant_isolation ON #{table}
              USING (app_scope() = 'tenant' AND #{column} = app_tenant_id());
          SQL
        end
        dir.down do
          execute <<~SQL
            DROP POLICY IF EXISTS tenant_isolation ON #{table};
            ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY;
          SQL
        end
      end
    end
  end
end
