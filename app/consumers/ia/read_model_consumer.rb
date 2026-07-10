module Ia
  # S1-G5 · I4 — the IA satellite ingests domain events into its read models (ADR-0007).
  # Read-side only: outputs are suggestions/projections, never writes to core. Scaffold.
  class ReadModelConsumer < Consumer::Base
    def handle(event)
      IaReadModel.create!(kind: event.event_type, subject_tenant_id: event.tenant_id, data: event.payload)
    end
  end
end
