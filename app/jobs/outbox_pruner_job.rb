# S1-G2 · I7 — recurring retention sweep. Runs under svc_outbox (G1 job guard).
class OutboxPrunerJob < ApplicationJob
  requires_scope!

  def perform
    OutboxPruner.run
  end

  def rls_scope
    { scope_type: "svc_outbox" }
  end
end
