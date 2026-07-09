# S1-G2 · I2 / D5 — idempotent consumer wrapper.
#
# Insert the ledger row and run the consumer's effects IN THE SAME TRANSACTION:
#   * ON CONFLICT DO NOTHING on the (consumer_name, event_id) unique index — a replay
#     inserts nothing, so the effects are skipped (exactly-once).
#   * if the effects raise, the whole transaction rolls back — the ledger row and the
#     effects disappear together, so redelivery reprocesses cleanly.
# Consumers never implement their own dedup; they just define #handle.
module Consumer
  class Base
    def self.consumer_name
      name
    end

    def self.process(event)
      ApplicationRecord.transaction do
        inserted = ProcessedEvent.insert_all(
          [ { consumer_name: consumer_name, event_id: event.id, processed_at: Time.current } ],
          unique_by: %i[consumer_name event_id],
          returning: %w[id]
        )
        next if inserted.rows.empty? # already processed — replay is a no-op

        new.handle(event)
      end
    end

    def handle(_event)
      raise NotImplementedError, "#{self.class} must implement #handle"
    end
  end
end
