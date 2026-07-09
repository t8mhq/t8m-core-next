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

    # S1-G1 · I2 / D5 — additive, SELECT-only grant-read policy (Shape B). Widens read
    # access on a tenant-scoped table to a grantee whose non-revoked grants cover the
    # row's tenant. Reads via granted_tenants() (SECURITY DEFINER) so it does not couple
    # to the access_grants self-policy. Never grants write (no WITH CHECK / no FOR ALL).
    def add_grant_read(table, column: :tenant_id)
      reversible do |dir|
        dir.up do
          execute <<~SQL
            CREATE POLICY grant_read ON #{table}
              FOR SELECT
              USING (app_scope() = 'grant' AND #{column} IN (SELECT granted_tenants(app_user_id())));
          SQL
        end
        dir.down { execute "DROP POLICY IF EXISTS grant_read ON #{table};" }
      end
    end

    # S1-G1 · I3 — the three marketplace scopes on a marketplace-owned table.
    #   mkt_platform : cross-tenant, all commands (platform operates the marketplace)
    #   mkt_seller   : the seller sees/writes only its own rows
    #   mkt_public   : SELECT only, only rows meeting the published predicate (optional)
    # These policies never mention 'tenant' scope, so a plain tenant session sees zero
    # marketplace rows (default-deny). Likewise no core table names 'mkt_platform', so
    # mkt_platform reads zero core rows — the matrix's bold cell, kept true by the tests.
    def enable_marketplace_rls(table, seller_column: :seller_tenant_id, published_column: nil)
      reversible do |dir|
        dir.up do
          execute <<~SQL
            ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY;
            ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;
            CREATE POLICY mkt_platform_all ON #{table}
              USING (app_scope() = 'mkt_platform');
            CREATE POLICY mkt_seller_own ON #{table}
              USING (app_scope() = 'mkt_seller' AND #{seller_column} = app_tenant_id());
          SQL
          if published_column
            execute <<~SQL
              CREATE POLICY mkt_public_published ON #{table}
                FOR SELECT
                USING (app_scope() = 'mkt_public' AND #{published_column} = 'published');
            SQL
          end
        end
        dir.down do
          execute <<~SQL
            DROP POLICY IF EXISTS mkt_platform_all ON #{table};
            DROP POLICY IF EXISTS mkt_seller_own ON #{table};
            DROP POLICY IF EXISTS mkt_public_published ON #{table};
            ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY;
          SQL
        end
      end
    end
  end
end
