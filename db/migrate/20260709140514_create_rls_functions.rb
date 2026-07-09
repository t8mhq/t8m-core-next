# S1-G1 · D3 — context-reading SQL helpers (annex §1).
# current_setting(key, true) returns NULL (not error) when unset — the default-deny path.
class CreateRlsFunctions < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE FUNCTION app_scope() RETURNS text
        LANGUAGE sql STABLE AS
        $$ SELECT current_setting('app.scope_type', true) $$;

      CREATE FUNCTION app_tenant_id() RETURNS uuid
        LANGUAGE sql STABLE AS
        $$ SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid $$;

      CREATE FUNCTION app_user_id() RETURNS uuid
        LANGUAGE sql STABLE AS
        $$ SELECT NULLIF(current_setting('app.user_id', true), '')::uuid $$;
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION IF EXISTS app_scope();
      DROP FUNCTION IF EXISTS app_tenant_id();
      DROP FUNCTION IF EXISTS app_user_id();
    SQL
  end
end
