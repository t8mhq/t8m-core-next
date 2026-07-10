module Orders
  # S1-G5 · I2 — the orders pack public API. Marketplace materializes sub-orders through
  # here (never writing core tables directly, ADR-0004); backoffice reads through here too.
  module Api
    module_function

    def materialize_suborder(marketplace_order_id:, total_cents:)
      Orders::Order.create!(
        tenant_id: ActiveRecord::Base.connection.select_value("SELECT app_tenant_id()"),
        channel: "marketplace",
        marketplace_order_ref: marketplace_order_id,
        total_cents: total_cents,
        status: "confirmed"
      )
    end

    # The sub-orders materialized for a marketplace order (in the current tenant scope).
    def suborders(marketplace_order_ref:)
      Orders::Order.where(marketplace_order_ref: marketplace_order_ref, channel: "marketplace").to_a
    end
  end
end
