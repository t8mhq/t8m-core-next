require "test_helper"

# S1-G1 · I1 — tenant scope proven against a real policy as app_user.
# RLS + explicit connection control ⇒ no transactional fixtures; we clean up by hand
# under each tenant's context (app_user cannot bypass RLS to truncate).
class TenantScopeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @a = Tenant.create!(name: "Tenant A")
    @b = Tenant.create!(name: "Tenant B")
    seed(@a, "a1")
    seed(@b, "b1")
    Rls.reset(connection: conn)
  end

  teardown do
    [ @a, @b ].compact.each do |t|
      Rls.set(scope_type: "tenant", tenant_id: t.id, connection: conn)
      Probe.where(tenant_id: t.id).delete_all
    end
    Rls.reset(connection: conn)
    Tenant.where(id: [ @a&.id, @b&.id ].compact).delete_all
  end

  test "a tenant context sees only its own rows (positive)" do
    Rls.set(scope_type: "tenant", tenant_id: @a.id, connection: conn)
    assert_equal [ "a1" ], Probe.order(:label).pluck(:label)
  ensure
    Rls.reset(connection: conn)
  end

  test "no context returns zero rows (default deny — D4)" do
    Rls.reset(connection: conn)
    assert_equal 0, Probe.count
    assert_nil Rls.current_scope(connection: conn)
  end

  test "insert is constrained to the session tenant (WITH CHECK)" do
    Rls.set(scope_type: "tenant", tenant_id: @a.id, connection: conn)
    # trying to write a row for tenant B while in tenant A context is rejected by policy
    assert_raises(ActiveRecord::StatementInvalid) do
      Probe.create!(tenant_id: @b.id, label: "smuggled")
    end
  ensure
    Rls.reset(connection: conn)
  end

  test "reset between requests prevents cross-tenant leak on a pinned connection (I1.2)" do
    # request 1 — tenant A on this connection
    Rls.set(scope_type: "tenant", tenant_id: @a.id, connection: conn)
    assert_equal [ "a1" ], Probe.pluck(:label)
    Rls.reset(connection: conn) # the reset the middleware ensure-block performs on release

    # request 2 — tenant B reuses the SAME pooled connection
    Rls.set(scope_type: "tenant", tenant_id: @b.id, connection: conn)
    labels = Probe.pluck(:label)
    assert_equal [ "b1" ], labels, "tenant B must never observe tenant A rows"
  ensure
    Rls.reset(connection: conn)
  end

  private

  def seed(tenant, label)
    Rls.set(scope_type: "tenant", tenant_id: tenant.id, connection: conn)
    Probe.create!(tenant: tenant, label: label)
  ensure
    Rls.reset(connection: conn)
  end
end
