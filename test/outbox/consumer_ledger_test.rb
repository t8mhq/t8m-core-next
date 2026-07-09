require "test_helper"

# S1-G2 · I2 — the idempotency ledger, exercised as app_user.
class ConsumerLedgerTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  # Writes its effect, then raises — for the same-transaction rollback proof.
  class FailingConsumer < Consumer::Base
    def handle(event)
      ConsumerEffect.create!(consumer_name: self.class.consumer_name, event_id: event.id)
      raise "effect failed"
    end
  end

  # A distinct consumer (different consumer_name) sharing the reference behaviour.
  class SecondConsumer < Consumer::Reference; end

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    @probe = Probe.create!(tenant: @tenant, label: "agg")
    @event = ActiveRecord::Base.transaction do
      DomainEvents.publish(event_type: "x@v1", aggregate: @probe, payload: {})
    end
    Rls.reset(connection: conn)
  end

  teardown do
    ProcessedEvent.delete_all
    ConsumerEffect.delete_all
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    DomainEvent.where(tenant_id: @tenant.id).delete_all
    Probe.where(tenant_id: @tenant.id).delete_all
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "delivering the same event twice produces the effect exactly once (I2.1)" do
    Consumer::Reference.process(@event)
    Consumer::Reference.process(@event)
    assert_equal 1, ConsumerEffect.where(event_id: @event.id, consumer_name: "Consumer::Reference").count
    assert_equal 1, ProcessedEvent.where(event_id: @event.id, consumer_name: "Consumer::Reference").count
  end

  test "consumer failure after ledger insert rolls back both (I2.2)" do
    name = "ConsumerLedgerTest::FailingConsumer"
    assert_raises(RuntimeError) { FailingConsumer.process(@event) }
    assert_equal 0, ProcessedEvent.where(event_id: @event.id, consumer_name: name).count, "ledger rolled back"
    assert_equal 0, ConsumerEffect.where(event_id: @event.id, consumer_name: name).count, "effect rolled back"
  end

  test "two different consumers process the same event independently (I2.3)" do
    Consumer::Reference.process(@event)
    SecondConsumer.process(@event)
    assert_equal 2, ProcessedEvent.where(event_id: @event.id).count
    assert_equal 2, ConsumerEffect.where(event_id: @event.id).count
    assert_equal [ "Consumer::Reference", "ConsumerLedgerTest::SecondConsumer" ],
      ProcessedEvent.where(event_id: @event.id).pluck(:consumer_name).sort
  end
end
