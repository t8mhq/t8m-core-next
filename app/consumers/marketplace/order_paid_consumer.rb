module Marketplace
  # S1-G5 · I2 — on marketplace_order_paid, materialize the seller sub-order(s). Wiring
  # over SubOrderMaterializer; guarded by the idempotency ledger (Consumer::Base).
  class OrderPaidConsumer < Consumer::Base
    def handle(event)
      payload = event.payload
      SubOrderMaterializer.materialize(
        marketplace_order_id: payload["marketplace_order_id"],
        seller_tenant_id: payload["seller_tenant_id"],
        total_cents: payload["total_cents"]
      )
    end
  end
end
