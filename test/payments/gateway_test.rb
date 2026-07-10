require "test_helper"

# S1-G4 · I1 — the PaymentGateway interface + Pagar.me (mock) adapter, as app_user.
class PaymentsGatewayTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
  end

  teardown do
    in_scope { Payments::Payment.where(tenant_id: @tenant.id).delete_all }
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "create_charge records a pagarme charge awaiting webhook confirmation" do
    in_scope do
      charge = Payments::Api.create_charge(method: "pix", amount_cents: 5000)
      assert charge.persisted?
      assert_equal "pagarme", charge.provider
      assert_equal "awaiting_payment", charge.status
      assert charge.gateway_charge_id.present?
    end
  end

  test "fetch_status delegates to the gateway" do
    in_scope do
      charge = Payments::Api.create_charge(method: "card", amount_cents: 1000)
      assert_equal "awaiting_payment", Payments::Api.fetch_status(charge)
    end
  end

  test "an unsupported method is rejected" do
    in_scope do
      assert_raises(ArgumentError) { Payments::Api.create_charge(method: "cheque", amount_cents: 100) }
    end
  end

  private

  def in_scope
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
