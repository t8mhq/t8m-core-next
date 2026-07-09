# S1-G2 · I1 — placeholder for consumer dispatch. G2-I2 wires the idempotency ledger
# and real consumers behind this; in I1 it exists so the publisher has something to
# enqueue and the crash tests can observe delivery.
class OutboxDeliveryJob < ApplicationJob
  def perform(event_id)
    # I2: route event_id to subscribed consumers (each guarded by the ledger).
  end
end
