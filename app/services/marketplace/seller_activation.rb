module Marketplace
  # S1-G5 · I5 — seller activation gates listing (ADR-0004 §consequences). BOTH gates must
  # pass — fiscal readiness (ADR-0006) AND payment recipient KYC (ADR-0005) — before a
  # seller's items are listable. Fail either and the seller's profiles are never published,
  # so the buyer portal (mkt_public) shows zero. Runs under mkt_platform.
  class SellerActivation
    def self.activate(seller_tenant_id:)
      return :fiscal_blocked unless fiscal_ready?(seller_tenant_id)
      return :recipient_blocked unless Payments::Api.recipient_approved?(seller_tenant_id)

      Marketplace::SellerProfile
        .where(seller_tenant_id: seller_tenant_id)
        .update_all(listing_status: "published")
      :active
    end

    def self.fiscal_ready?(seller_tenant_id)
      Rls.with_scope(scope_type: "tenant", tenant_id: seller_tenant_id) do
        Fiscal::Api.ready?(seller_tenant_id)
      end
    end
  end
end
