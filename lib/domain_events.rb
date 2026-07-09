# S1-G2 · I1 / D1+D2 — the ONLY write path into the outbox.
#
# publish RAISES outside an open transaction (D1), so a dual-write (domain change
# committed without its event, or vice versa) is impossible to write. The sequence is
# per-aggregate (D2), assigned as MAX+1 — correct under the aggregate row's lock, which
# every legitimate caller already holds; a concurrent publish for an unlocked aggregate
# surfaces loudly as a uniqueness error on idx_domain_events_aggregate_sequence.
module DomainEvents
  class OutsideTransaction < StandardError; end

  module_function

  def publish(event_type:, aggregate:, payload:, connection: ActiveRecord::Base.connection)
    if connection.open_transactions.zero?
      raise OutsideTransaction, "DomainEvents.publish requires an open transaction (D1)"
    end

    EventSchema.validate!(event_type, payload) if EventSchema.enabled?

    aggregate_type = aggregate.class.base_class.name
    aggregate_id = aggregate.id

    DomainEvent.create!(
      tenant_id: connection.select_value("SELECT app_tenant_id()"),
      aggregate_type: aggregate_type,
      aggregate_id: aggregate_id,
      sequence: next_sequence(aggregate_type, aggregate_id, connection),
      event_type: event_type,
      payload: payload,
      occurred_at: Time.current
    )
  end

  def next_sequence(aggregate_type, aggregate_id, connection)
    connection.select_value(
      DomainEvent.sanitize_sql_array(
        [ "SELECT COALESCE(MAX(sequence), 0) + 1 FROM domain_events WHERE aggregate_type = ? AND aggregate_id = ?",
          aggregate_type, aggregate_id ]
      )
    )
  end
end
