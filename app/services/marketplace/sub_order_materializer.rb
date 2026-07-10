module Marketplace
  # S1-G5 · I2 — materialize one sub-order per seller in that seller's tenant, through the
  # core's public API (ADR-0004: "through the front door", never writing core tables
  # directly). Happy-path walking skeleton.
  class SubOrderMaterializer
    def self.materialize(marketplace_order_id:, seller_tenant_id:, total_cents:)
      Rls.with_scope(scope_type: "tenant", tenant_id: seller_tenant_id) do
        Orders::Api.materialize_suborder(marketplace_order_id: marketplace_order_id, total_cents: total_cents)
      end
    end
  end
end
