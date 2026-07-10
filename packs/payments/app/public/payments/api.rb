module Payments
  # S1-G4 — the payments pack's public API. Isolates the gateway (ADR-0005); everything
  # outside the pack (and the webhook consumer) goes through here.
  module Api
    module_function

    # The configured PaymentGateway adapter. Swappable (tests inject a fake).
    def gateway
      @gateway ||= PagarmeAdapter.new
    end

    def gateway=(adapter)
      @gateway = adapter
    end

    # Create a gateway charge and record it (awaiting_payment; confirmed only by webhook).
    def create_charge(method:, amount_cents:, split: nil)
      charge = gateway.create_charge(method: method, amount_cents: amount_cents, split: split)
      Payments::Payment.create!(
        tenant_id: ActiveRecord::Base.connection.select_value("SELECT app_tenant_id()"),
        provider: "pagarme",
        method: method,
        amount_cents: amount_cents,
        gateway_charge_id: charge.id,
        status: charge.status
      )
    end

    def fetch_status(payment)
      gateway.fetch_status(payment.gateway_charge_id)
    end

    # --- recipients (I3) ---

    def register_recipient(tenant_id: current_tenant)
      Payments::Recipient.create!(
        tenant_id: tenant_id,
        recipient_id: gateway.register_recipient(tenant_id: tenant_id),
        kyc_status: "pending"
      )
    end

    # Simulates Pagar.me KYC approval (real: driven by a webhook, I2).
    def approve_recipient(recipient)
      recipient.update!(kyc_status: "approved")
    end

    def recipient_approved?(tenant_id)
      Payments::Recipient.where(tenant_id: tenant_id, kyc_status: "approved").exists?
    end

    def current_tenant
      ActiveRecord::Base.connection.select_value("SELECT app_tenant_id()")
    end
  end
end
