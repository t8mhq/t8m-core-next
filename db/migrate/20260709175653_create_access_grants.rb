# S1-G1 · I2 / D6 — access grants + grant scope (read-only in Stage 1, D5).
class CreateAccessGrants < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def up
    create_table :access_grants, id: :uuid do |t|
      t.references :grantor_tenant, type: :uuid, null: false,
        foreign_key: { to_table: :tenants }
      t.uuid :grantee_user_id, null: false     # a user id (no users table in G1)
      t.string :role, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :access_grants, %i[grantee_user_id revoked_at]

    execute <<~SQL
      ALTER TABLE access_grants ENABLE ROW LEVEL SECURITY;
      ALTER TABLE access_grants FORCE ROW LEVEL SECURITY;

      -- D6: the grantor tenant manages its own grants (all commands).
      CREATE POLICY grantor_manages ON access_grants
        USING (app_scope() = 'tenant' AND grantor_tenant_id = app_tenant_id());

      -- D6: a grantee reads only its own grant rows (to resolve its own scope).
      CREATE POLICY grantee_reads_own ON access_grants
        FOR SELECT
        USING (app_scope() = 'grant' AND grantee_user_id = app_user_id());

      -- Shape B: resolve a grantee's tenants bypassing RLS on access_grants for this
      -- lookup only. SET search_path is mandatory (definer without it = escalation vector).
      CREATE FUNCTION granted_tenants(uid uuid) RETURNS SETOF uuid
        LANGUAGE sql STABLE SECURITY DEFINER
        SET search_path = public AS
        $$ SELECT grantor_tenant_id FROM access_grants
           WHERE grantee_user_id = uid AND revoked_at IS NULL $$;
    SQL

    # grant-scope read on the representative tenant-scoped table
    add_grant_read :probes
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS grant_read ON probes;
      DROP FUNCTION IF EXISTS granted_tenants(uuid);
    SQL
    drop_table :access_grants
  end
end
