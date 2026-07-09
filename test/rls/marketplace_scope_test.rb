require "test_helper"

# S1-G1 · I3 — the three marketplace scopes proven as app_user, plus the two
# cross-scope negatives (the matrix's bold cell and the tenant↔marketplace isolation).
class MarketplaceScopeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @a = Tenant.create!(name: "A")
    @b = Tenant.create!(name: "B")
    @tenants = [ @a, @b ]
    seed_probe(@a, "core_a") # a core tenant-scoped row for the bold-cell negative

    Rls.set(scope_type: "mkt_platform", connection: conn) # platform seeds cross-tenant
    Marketplace::SellerProfile.create!(seller_tenant: @a, listing_status: "published", display_name: "A shop")
    Marketplace::SellerProfile.create!(seller_tenant: @a, listing_status: "draft", display_name: "A draft")
    Marketplace::SellerProfile.create!(seller_tenant: @b, listing_status: "published", display_name: "B shop")
    Rls.reset(connection: conn)
  end

  teardown do
    Rls.set(scope_type: "mkt_platform", connection: conn)
    Marketplace::SellerProfile.delete_all
    Marketplace::MarketplaceOrder.delete_all
    Rls.reset(connection: conn)
    @tenants.each do |t|
      Rls.set(scope_type: "tenant", tenant_id: t.id, connection: conn)
      Probe.where(tenant_id: t.id).delete_all
    end
    Rls.reset(connection: conn)
    Tenant.where(id: @tenants.map(&:id)).delete_all
  end

  test "mkt_seller reads only its own rows, drafts included (I3.1)" do
    Rls.set(scope_type: "mkt_seller", tenant_id: @a.id, connection: conn)
    assert_equal [ "A draft", "A shop" ], Marketplace::SellerProfile.order(:display_name).pluck(:display_name)
  ensure
    Rls.reset(connection: conn)
  end

  test "mkt_public reads only published rows (I3.2)" do
    Rls.set(scope_type: "mkt_public", connection: conn)
    assert_equal [ "A shop", "B shop" ], Marketplace::SellerProfile.order(:display_name).pluck(:display_name)
  ensure
    Rls.reset(connection: conn)
  end

  test "mkt_platform reads marketplace rows but ZERO core rows (I3.3 — bold cell)" do
    Rls.set(scope_type: "mkt_platform", connection: conn)
    assert_equal 3, Marketplace::SellerProfile.count
    assert_equal 0, Probe.count, "mkt_platform must not leak into core tenant-scoped tables"
  ensure
    Rls.reset(connection: conn)
  end

  test "plain tenant scope sees zero marketplace rows (I3.4)" do
    Rls.set(scope_type: "tenant", tenant_id: @a.id, connection: conn)
    assert_equal 1, Probe.count, "tenant sees its own core row"
    assert_equal 0, Marketplace::SellerProfile.count, "but zero marketplace rows"
  ensure
    Rls.reset(connection: conn)
  end

  private

  def seed_probe(tenant, label)
    Rls.set(scope_type: "tenant", tenant_id: tenant.id, connection: conn)
    Probe.create!(tenant: tenant, label: label)
  ensure
    Rls.reset(connection: conn)
  end
end
