require "test_helper"

# S1-G1 · I5 — the full scope × table matrix, asserted explicitly as app_user.
# Every default-deny cell (a scope with no matching policy on a table ⇒ zero rows) is
# asserted, not merely assumed. Complements the focused per-scope tests.
#
# Seed: core probes for A and B; grants uid→{A,B} and other→{C}; published seller
# profiles for A and B.
class ScopeMatrixTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @a = Tenant.create!(name: "A")
    @b = Tenant.create!(name: "B")
    @c = Tenant.create!(name: "C")
    @tenants = [ @a, @b, @c ]
    @uid = SecureRandom.uuid
    @other = SecureRandom.uuid

    in_tenant(@a) { Probe.create!(tenant: @a, label: "core_a") }
    in_tenant(@b) { Probe.create!(tenant: @b, label: "core_b") }
    in_tenant(@a) { AccessGrant.create!(grantor_tenant: @a, grantee_user_id: @uid, role: "r") }
    in_tenant(@b) { AccessGrant.create!(grantor_tenant: @b, grantee_user_id: @uid, role: "r") }
    in_tenant(@c) { AccessGrant.create!(grantor_tenant: @c, grantee_user_id: @other, role: "r") }
    as_mkt_platform do
      Marketplace::SellerProfile.create!(seller_tenant: @a, listing_status: "published", display_name: "A")
      Marketplace::SellerProfile.create!(seller_tenant: @b, listing_status: "published", display_name: "B")
    end
    Rls.reset(connection: conn)
  end

  teardown do
    as_mkt_platform do
      Marketplace::SellerProfile.delete_all
      Marketplace::MarketplaceOrder.delete_all
    end
    @tenants.each do |t|
      in_tenant(t) do
        AccessGrant.where(grantor_tenant_id: t.id).delete_all
        Probe.where(tenant_id: t.id).delete_all
      end
    end
    Rls.reset(connection: conn)
    Tenant.where(id: @tenants.map(&:id)).delete_all
  end

  test "every scope x table cell has the expected visibility" do
    cells = [
      [ "tenant A",     -> { Rls.set(scope_type: "tenant", tenant_id: @a.id, connection: conn) },     { probe: 1, grant: 1, seller: 0 } ],
      [ "tenant B",     -> { Rls.set(scope_type: "tenant", tenant_id: @b.id, connection: conn) },     { probe: 1, grant: 1, seller: 0 } ],
      [ "grant (A,B)",  -> { Rls.set(scope_type: "grant", user_id: @uid, connection: conn) },         { probe: 2, grant: 2, seller: 0 } ],
      [ "mkt_seller A", -> { Rls.set(scope_type: "mkt_seller", tenant_id: @a.id, connection: conn) }, { probe: 0, grant: 0, seller: 1 } ],
      [ "mkt_platform", -> { Rls.set(scope_type: "mkt_platform", connection: conn) },                 { probe: 0, grant: 0, seller: 2 } ],
      [ "mkt_public",   -> { Rls.set(scope_type: "mkt_public", connection: conn) },                   { probe: 0, grant: 0, seller: 2 } ],
      [ "no context",   -> { Rls.reset(connection: conn) },                                           { probe: 0, grant: 0, seller: 0 } ]
    ]

    cells.each do |label, set_scope, expected|
      set_scope.call
      assert_equal expected[:probe],  Probe.count,                      "#{label} x core tenant"
      assert_equal expected[:grant],  AccessGrant.count,                "#{label} x access_grants"
      assert_equal expected[:seller], Marketplace::SellerProfile.count, "#{label} x marketplace"
    ensure
      Rls.reset(connection: conn)
    end
  end

  private

  def in_tenant(tenant)
    Rls.set(scope_type: "tenant", tenant_id: tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end

  def as_mkt_platform
    Rls.set(scope_type: "mkt_platform", connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
