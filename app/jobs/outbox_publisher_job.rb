# S1-G2 · I1 / D3 — the recurring publisher. Runs under svc_outbox (G1 job guard),
# scheduled by Solid Queue (config/recurring.yml).
class OutboxPublisherJob < ApplicationJob
  requires_scope!

  def perform
    OutboxPublisher.run
  end

  def rls_scope
    { scope_type: "svc_outbox" }
  end
end
