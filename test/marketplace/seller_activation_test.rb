require "test_helper"

# S1-G5 · I5 — seller activation gates listing, as app_user.
#   A: fiscal ready + recipient approved → active, listable.
#   B: fiscal ready, NO recipient        → recipient_blocked, zero listable.
#   C: recipient approved, NO fiscal     → fiscal_blocked, zero listable.
class SellerActivationTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @a = Tenant.create!(name: "Seller A")
    @b = Tenant.create!(name: "Seller B")
    @c = Tenant.create!(name: "Seller C")
    [ @a, @b, @c ].each { |t| create_profile(t) }
    set_fiscal(@a); set_fiscal(@b)
    approve_recipient(@a); approve_recipient(@c)
  end

  teardown do
    as_platform { Marketplace::SellerProfile.where(seller_tenant_id: [ @a.id, @b.id, @c.id ]).delete_all }
    [ @a, @b, @c ].each do |t|
      in_tenant(t) do
        Fiscal::TenantParameter.where(tenant_id: t.id).delete_all
        Payments::Recipient.where(tenant_id: t.id).delete_all
      end
    end
    Rls.reset(connection: conn)
    Tenant.where(id: [ @a.id, @b.id, @c.id ]).delete_all
  end

  test "a seller passing both gates activates and becomes listable (I5)" do
    as_platform do
      assert_equal :active, Marketplace::SellerActivation.activate(seller_tenant_id: @a.id)
    end
    assert_equal 1, listable_count(@a), "listable in the buyer portal"
  end

  test "a seller without an approved recipient is recipient_blocked and has zero listable items" do
    as_platform do
      assert_equal :recipient_blocked, Marketplace::SellerActivation.activate(seller_tenant_id: @b.id)
    end
    assert_equal 0, listable_count(@b)
  end

  test "a seller without fiscal readiness is fiscal_blocked and has zero listable items" do
    as_platform do
      assert_equal :fiscal_blocked, Marketplace::SellerActivation.activate(seller_tenant_id: @c.id)
    end
    assert_equal 0, listable_count(@c)
  end

  private

  def listable_count(tenant)
    Rls.set(scope_type: "mkt_public", connection: conn)
    Marketplace::SellerProfile.where(seller_tenant_id: tenant.id).count
  ensure
    Rls.reset(connection: conn)
  end

  def create_profile(tenant)
    as_platform { Marketplace::SellerProfile.create!(seller_tenant: tenant, listing_status: "draft", display_name: tenant.name) }
  end

  def set_fiscal(tenant)
    in_tenant(tenant) do
      Fiscal::TenantParameter.create!(tenant_id: tenant.id, rate_bps: 400, annex: "I", valid_from: Date.new(2026, 1, 1))
    end
  end

  def approve_recipient(tenant)
    in_tenant(tenant) { Payments::Api.approve_recipient(Payments::Api.register_recipient) }
  end

  def as_platform
    Rls.set(scope_type: "mkt_platform", connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end

  def in_tenant(tenant)
    Rls.set(scope_type: "tenant", tenant_id: tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
