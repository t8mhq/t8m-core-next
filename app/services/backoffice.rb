# S1-G5 · I6 — minimal backoffice operator queries (read-only). Aggregates state an
# operator needs; more views land as debt. Reads through pack public APIs.
module Backoffice
  module_function

  # A marketplace order's sub-orders across the seller tenants (read under each scope).
  def marketplace_suborders(marketplace_order_id:, seller_tenant_ids:)
    seller_tenant_ids.flat_map do |tenant_id|
      Rls.with_scope(scope_type: "tenant", tenant_id: tenant_id) do
        Orders::Api.suborders(marketplace_order_ref: marketplace_order_id)
      end
    end
  end

  # Outbox health: unpublished events are an incident signal (ADR-0002).
  def unpublished_event_count
    Rls.set(scope_type: "svc_outbox")
    DomainEvent.unpublished.count
  ensure
    Rls.reset
  end
end
