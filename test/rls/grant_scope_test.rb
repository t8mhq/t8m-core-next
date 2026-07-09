require "test_helper"

# S1-G1 · I2 — grant scope proven as app_user against the real policies.
# Grantee `@uid` holds grants on tenants A and B; `@other_uid` holds a grant on C.
class GrantScopeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @a = Tenant.create!(name: "A")
    @b = Tenant.create!(name: "B")
    @c = Tenant.create!(name: "C")
    @tenants = [ @a, @b, @c ]
    @tenants.each { |t| seed_probe(t, "#{t.name.downcase}1") }

    @uid = SecureRandom.uuid
    @other_uid = SecureRandom.uuid
    grant(grantor: @a, grantee: @uid)
    grant(grantor: @b, grantee: @uid)
    grant(grantor: @c, grantee: @other_uid)
    Rls.reset(connection: conn)
  end

  teardown do
    @tenants.each do |t|
      Rls.set(scope_type: "tenant", tenant_id: t.id, connection: conn)
      AccessGrant.where(grantor_tenant_id: t.id).delete_all
      Probe.where(tenant_id: t.id).delete_all
    end
    Rls.reset(connection: conn)
    Tenant.where(id: @tenants.map(&:id)).delete_all
  end

  test "grantee reads granted tenants' rows and nothing else (I2.1)" do
    grant_scope(@uid)
    assert_equal %w[a1 b1], Probe.order(:label).pluck(:label), "sees A+B, never C"
  ensure
    Rls.reset(connection: conn)
  end

  test "revoking a grant removes access in the next transaction (I2.2)" do
    grant_scope(@uid)
    assert_includes Probe.pluck(:label), "b1"

    Rls.set(scope_type: "tenant", tenant_id: @b.id, connection: conn) # grantor B revokes
    n = AccessGrant.where(grantor_tenant_id: @b.id, grantee_user_id: @uid).update_all(revoked_at: Time.current)
    assert_equal 1, n

    grant_scope(@uid)
    assert_equal %w[a1], Probe.order(:label).pluck(:label), "B access gone after revoke"
  ensure
    Rls.reset(connection: conn)
  end

  test "grant scope cannot write to a tenant-scoped table (I2.3 / D5)" do
    grant_scope(@uid)
    assert_raises(ActiveRecord::StatementInvalid, "INSERT must be rejected") do
      Probe.create!(tenant_id: @a.id, label: "x")
    end
    assert_equal 0, Probe.where(label: "a1").update_all(label: "hacked"), "UPDATE blocked"
    assert_equal 0, Probe.where(label: "a1").delete_all, "DELETE blocked"
  ensure
    Rls.reset(connection: conn)
  end

  test "a grantee cannot read another grantee's grants (I2.4 / D6)" do
    grant_scope(@uid)
    assert_equal [ @uid ], AccessGrant.pluck(:grantee_user_id).uniq, "only own grants"
    assert_equal 0, AccessGrant.where(grantee_user_id: @other_uid).count, "others' grants invisible"
  ensure
    Rls.reset(connection: conn)
  end

  private

  def grant_scope(uid) = Rls.set(scope_type: "grant", user_id: uid, connection: conn)

  def seed_probe(tenant, label)
    Rls.set(scope_type: "tenant", tenant_id: tenant.id, connection: conn)
    Probe.create!(tenant: tenant, label: label)
  ensure
    Rls.reset(connection: conn)
  end

  def grant(grantor:, grantee:)
    Rls.set(scope_type: "tenant", tenant_id: grantor.id, connection: conn)
    AccessGrant.create!(grantor_tenant: grantor, grantee_user_id: grantee, role: "accountant")
  ensure
    Rls.reset(connection: conn)
  end
end
