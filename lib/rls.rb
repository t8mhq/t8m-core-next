# S1-G1 · D3 — Runtime RLS context transport.
#
# Sets the Postgres session variables the policies read (app.scope_type,
# app.tenant_id, app.user_id) on a given connection. Two modes:
#   local: false — session-level; used at the HTTP connection lease, cleared by an
#                  ensure-block on release (RlsContextMiddleware).
#   local: true  — transaction-local; used by jobs inside an explicit transaction so
#                  context provably vanishes at commit/rollback (G1-I4).
#
# Empty string is written for absent ids; the SQL helpers NULLIF('') them back to
# NULL, which makes every policy predicate false ⇒ default-deny (D4).
module Rls
  SCOPES = %w[tenant grant mkt_platform mkt_seller mkt_public].freeze

  module_function

  def set(scope_type:, tenant_id: nil, user_id: nil, local: false,
          connection: ActiveRecord::Base.connection)
    is_local = local ? "true" : "false"
    connection.exec_query(<<~SQL, "rls.set", [ scope_type.to_s, tenant_id.to_s, user_id.to_s ])
      SELECT set_config('app.scope_type', $1, #{is_local}),
             set_config('app.tenant_id',  $2, #{is_local}),
             set_config('app.user_id',    $3, #{is_local})
    SQL
  end

  def reset(connection: ActiveRecord::Base.connection)
    connection.exec_query(<<~SQL, "rls.reset")
      SELECT set_config('app.scope_type', '', false),
             set_config('app.tenant_id',  '', false),
             set_config('app.user_id',    '', false)
    SQL
  end

  # Current scope as the database sees it (nil when unset) — handy for tests/guards.
  def current_scope(connection: ActiveRecord::Base.connection)
    v = connection.select_value("SELECT app_scope()")
    v.to_s.empty? ? nil : v
  end
end
