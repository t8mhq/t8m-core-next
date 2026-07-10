module Payments
  # S1-G4 · I4 — split-rule construction for multi-seller charges (ADR-0005).
  # One buyer charge → N seller legs + platform commission. Two invariants, both enforced
  # at construction (runs under mkt_platform, which reads recipients):
  #   * sum(legs) + commission == total  (money is conserved — no leak, no phantom)
  #   * every targeted seller has an APPROVED Pagar.me recipient (else the split is refused)
  class Split
    Leg = Struct.new(:seller_tenant_id, :recipient_id, :amount_cents, keyword_init: true)
    Result = Struct.new(:legs, :commission_cents, keyword_init: true)

    class NotReconciled < StandardError; end
    class SellerNotApproved < StandardError; end

    def self.build(total_cents:, seller_amounts:, commission_cents:)
      distributed = seller_amounts.values.sum + commission_cents
      unless distributed == total_cents
        raise NotReconciled, "sum(legs)+commission=#{distributed} != total=#{total_cents}"
      end

      legs = seller_amounts.map do |tenant_id, amount_cents|
        recipient = Payments::Recipient.find_by(tenant_id: tenant_id, kyc_status: "approved")
        raise SellerNotApproved, "seller #{tenant_id} has no approved recipient" if recipient.nil?

        Leg.new(seller_tenant_id: tenant_id, recipient_id: recipient.recipient_id, amount_cents: amount_cents)
      end

      Result.new(legs: legs, commission_cents: commission_cents)
    end
  end
end
