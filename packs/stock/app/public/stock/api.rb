module Stock
  # S1-G2 · I4 — the stock pack's public API: the SINGLE write entry point for movements.
  # Everything outside the pack goes through here (Packwerk keeps the models private;
  # bin/lint-stock-writes keeps writes out of everywhere but this file).
  module Api
    module_function

    # Append an immutable movement, upsert the derived balance, and publish stock_moved
    # — all in one transaction (atomic with the outbox event, ADR-0002).
    def record_movement(product_id:, delta:, reason: nil, connection: ActiveRecord::Base.connection)
      Stock::Movement.transaction do
        tenant_id = connection.select_value("SELECT app_tenant_id()")
        movement = Stock::Movement.create!(tenant_id: tenant_id, product_id: product_id, delta: delta, reason: reason)
        upsert_balance(tenant_id: tenant_id, product_id: product_id, delta: delta)
        DomainEvents.publish(
          event_type: "stock_moved@v1",
          aggregate: movement,
          payload: { product_id: product_id.to_s, delta: delta }
        )
        movement
      end
    end

    # Reconciliation is read-only (alert-only) — exposed for the job and ops.
    def reconcile
      Stock::Reconciliation.run
    end

    def upsert_balance(tenant_id:, product_id:, delta:)
      Stock::Balance.upsert(
        { tenant_id: tenant_id, product_id: product_id, balance: delta },
        unique_by: %i[tenant_id product_id],
        on_duplicate: Arel.sql("balance = stock_balances.balance + EXCLUDED.balance")
      )
    end
  end
end
