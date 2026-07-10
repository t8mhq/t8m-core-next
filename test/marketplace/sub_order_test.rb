require "test_helper"

# S1-G5 · I2 — the marketplace walking skeleton, as app_user:
# a paid marketplace order → a sub-order in the seller's tenant → visible in backoffice.
class MarketplaceSubOrderTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @seller = Tenant.create!(name: "Seller A")
  end

  teardown do
    Rls.set(scope_type: "tenant", tenant_id: @seller.id, connection: conn)
    Orders::Order.where(tenant_id: @seller.id).delete_all
    Rls.reset(connection: conn)
    Tenant.where(id: @seller.id).delete_all
  end

  test "marketplace_order_paid materializes a seller sub-order, visible in backoffice" do
    marketplace_order_id = SecureRandom.uuid

    # the paid fact → what OrderPaidConsumer does on marketplace_order_paid
    Marketplace::SubOrderMaterializer.materialize(
      marketplace_order_id: marketplace_order_id, seller_tenant_id: @seller.id, total_cents: 5000
    )

    # the sub-order exists in the seller's tenant (same order model, channel=marketplace)
    Rls.with_scope(scope_type: "tenant", tenant_id: @seller.id, connection: conn) do
      suborders = Orders::Api.suborders(marketplace_order_ref: marketplace_order_id)
      assert_equal 1, suborders.size
      assert_equal "marketplace", suborders.first.channel
      assert_equal 5000, suborders.first.total_cents
    end

    # visible in backoffice (operator view aggregating across seller tenants)
    visible = Backoffice.marketplace_suborders(
      marketplace_order_id: marketplace_order_id, seller_tenant_ids: [ @seller.id ]
    )
    assert_equal 1, visible.size, "the sub-order is visible in backoffice"
  end
end
