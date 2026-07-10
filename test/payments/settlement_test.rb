require "test_helper"

# S1-G4 · I5 + I6 — settlement ingestion + fee capture, as app_user.
class PaymentsSettlementTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "Seller")
  end

  teardown do
    in_tenant do
      DomainEvent.where(tenant_id: @tenant.id).delete_all
      Payments::Settlement.where(tenant_id: @tenant.id).delete_all
    end
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "ingesting a settlement records the fact with its fee and publishes payment_settled" do
    in_tenant do
      settlement = Payments::Api.ingest_settlement(gateway_charge_id: "ch_abc", amount_cents: 9000, fee_cents: 250)

      assert settlement.persisted?
      assert_equal 250, settlement.fee_cents, "effective acquirer fee captured (I6)"
      assert_equal 9000, settlement.amount_cents
      assert_equal 1, DomainEvent.where(event_type: "payment_settled@v1").count, "payment_settled published (I5)"
    end
  end

  private

  def in_tenant
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
