# S1-G2 · I1 / D3 — the outbox publisher. Runs under the svc_outbox scope.
#
# Deliver-then-mark: deliver a consumer job, THEN mark published_at. A crash between
# the two leaves the row unpublished, so the next run redelivers — at-least-once by
# construction, never at-most-once. The consumer ledger (I2) absorbs the duplicate.
#
# `deliver` and `after_deliver` are injectable so the crash-between-deliver-and-mark
# scenario (I1.4) can be exercised at the exact boundary where the guarantee lives.
class OutboxPublisher
  DEFAULT_DELIVER = ->(event) { OutboxDeliveryJob.perform_later(event.id) }

  def self.run(deliver: DEFAULT_DELIVER, after_deliver: nil)
    # .each (not find_each) so D3's (aggregate_type, aggregate_id, sequence) order is
    # preserved — find_each forces id order. The unpublished set is bounded by cadence.
    DomainEvent.unpublished
               .order(:aggregate_type, :aggregate_id, :sequence)
               .each do |event|
      deliver.call(event)
      after_deliver&.call(event)          # test seam: simulate a crash before the mark
      event.update!(published_at: Time.current)
    end
  end
end
