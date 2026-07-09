# S1-G2 · I2 — the reference consumer: one observable write per event. Used by the
# replay tests; real consumers (marketplace/IA projections) arrive in G5.
module Consumer
  class Reference < Base
    def handle(event)
      ConsumerEffect.create!(consumer_name: self.class.consumer_name, event_id: event.id)
    end
  end
end
