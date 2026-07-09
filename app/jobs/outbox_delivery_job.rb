# S1-G2 · I1/I2 — dispatch a delivered event to its consumers, each guarded by the
# idempotency ledger (Consumer::Base). Runs under svc_outbox to read domain_events.
# Stage 1 has a single reference consumer; a registry is the extension point for G5.
class OutboxDeliveryJob < ApplicationJob
  requires_scope!

  CONSUMERS = [ Consumer::Reference ].freeze

  def perform(event_id)
    event = DomainEvent.find(event_id)
    CONSUMERS.each { |consumer| consumer.process(event) }
  end

  def rls_scope
    { scope_type: "svc_outbox" }
  end
end
