module Payments
  # S1-G4 · I1 — the Pagar.me adapter behind the PaymentGateway interface (ADR-0005).
  # A second gateway is a new adapter, not a rewrite. Mock for now: real Pagar.me HTTP
  # is debt (like the sidecar / Focus NFe). Card + Pix both start `awaiting_payment` —
  # confirmation is webhook-only (I2), never inline.
  class PagarmeAdapter
    METHODS = %w[card pix].freeze
    Charge = Struct.new(:id, :status, keyword_init: true)

    def create_charge(method:, amount_cents:, split: nil)
      raise ArgumentError, "unsupported method #{method.inspect}" unless METHODS.include?(method.to_s)

      Charge.new(id: "ch_#{SecureRandom.hex(8)}", status: "awaiting_payment")
    end

    def fetch_status(_gateway_charge_id)
      "awaiting_payment"
    end
  end
end
