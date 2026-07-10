require "test_helper"
require "pg"

# S1-G5 · I4 / ADR-0007 — the IA satellite's DB role can read the domain but PROVABLY
# cannot write core tables. Enforced by grants, not by convention.
class IaReadOnlyRoleTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "svc_ia reads core but cannot write core tables (I4)" do
    # reads a core table
    assert_nothing_raised { ia_exec("SELECT count(*) FROM domain_events") }

    # cannot write a core table
    err = assert_raises(PG::Error) do
      ia_exec("INSERT INTO probes (id, tenant_id, label) VALUES (gen_random_uuid(), gen_random_uuid(), 'x')")
    end
    assert_match(/permission denied/i, err.message)

    # CAN write its own read-model store
    assert_nothing_raised do
      ia_exec("INSERT INTO ia_read_models (id, kind, data, created_at, updated_at) VALUES (gen_random_uuid(), 'probe_touched', '{}', now(), now())")
    end
    ia_exec("DELETE FROM ia_read_models")
  end

  private

  def ia_exec(sql)
    db = ActiveRecord::Base.connection_db_config.configuration_hash
    pg = PG.connect(
      host: db[:host] || "localhost", port: db[:port] || 5432,
      user: "svc_ia", password: ENV.fetch("SVC_IA_PASSWORD", "svc_ia"), dbname: db[:database]
    )
    pg.exec(sql)
  ensure
    pg&.close
  end
end
