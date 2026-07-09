# S1-G2 · I7 — outbox retention with an archival carve-out. Runs under svc_outbox.
#
#   * old + published + NOT carve-out  → pruned (deleted).
#   * old + published + carve-out type → archived (stub), never pruned.
#   * unpublished                      → NEVER pruned regardless of age; an old one is
#                                        an incident, so it is alerted, not garbage.
class OutboxPruner
  CARVE_OUT_PREFIXES = %w[fiscal_ settlement_].freeze
  RETENTION = 90.days

  def self.run(now: Time.current)
    threshold = now - RETENTION

    alerts = DomainEvent.unpublished.where(occurred_at: ..threshold).pluck(:id)

    old_published = DomainEvent.where.not(published_at: nil).where(published_at: ..threshold).to_a
    carve_out, prunable = old_published.partition { |e| carve_out?(e.event_type) }

    carve_out.each { |event| archive(event) }
    DomainEvent.where(id: prunable.map(&:id)).delete_all if prunable.any?

    { pruned: prunable.size, archived: carve_out.size, alerts: alerts }
  end

  def self.carve_out?(event_type)
    CARVE_OUT_PREFIXES.any? { |prefix| event_type.start_with?(prefix) }
  end

  def self.archive(event)
    ArchivedEvent.create!(event_id: event.id, event_type: event.event_type, archived_at: Time.current)
  end
end
