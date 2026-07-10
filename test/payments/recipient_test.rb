require "test_helper"

# S1-G4 · I3 — Pagar.me recipients + KYC, as app_user.
class PaymentsRecipientTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "Seller")
  end

  teardown do
    in_tenant { Payments::Recipient.where(tenant_id: @tenant.id).delete_all }
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "register creates a pending recipient; approval flips KYC (I3)" do
    in_tenant do
      recipient = Payments::Api.register_recipient
      assert_equal "pending", recipient.kyc_status
      assert recipient.recipient_id.present?
      assert_not Payments::Api.recipient_approved?(@tenant.id)

      Payments::Api.approve_recipient(recipient)
      assert Payments::Api.recipient_approved?(@tenant.id)
    end
  end

  test "the platform can read recipient approval for split construction (mkt_platform)" do
    in_tenant do
      recipient = Payments::Api.register_recipient
      Payments::Api.approve_recipient(recipient)
    end
    Rls.set(scope_type: "mkt_platform", connection: conn)
    assert Payments::Api.recipient_approved?(@tenant.id), "mkt_platform reads recipients for splits"
  ensure
    Rls.reset(connection: conn)
  end

  private

  def in_tenant
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
