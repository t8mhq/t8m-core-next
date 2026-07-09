require "test_helper"

# S1-G2 · I1 — the outbox atomicity guarantee, exercised at the transaction boundary
# where the guarantee actually lives (per the gate's crash-test appendix). As app_user.
class DomainEventsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
    in_tenant { @probe = Probe.create!(tenant: @tenant, label: "agg") }
  end

  teardown do
    in_tenant do
      DomainEvent.where(tenant_id: @tenant.id).delete_all
      Probe.where(tenant_id: @tenant.id).delete_all
    end
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "publish outside a transaction raises (I1.2 / D1)" do
    in_tenant do
      assert_raises(DomainEvents::OutsideTransaction) do
        DomainEvents.publish(event_type: "probe_touched@v1", aggregate: @probe, payload: {})
      end
    end
  end

  test "rollback leaves zero rows in both tables (I1.1a)" do
    in_tenant do
      assert_raises(RuntimeError) do
        ActiveRecord::Base.transaction do
          p = Probe.create!(tenant_id: @tenant.id, label: "tx")
          DomainEvents.publish(event_type: "probe_created@v1", aggregate: p, payload: { label: "tx" })
          raise "boom"
        end
      end
      assert_equal 0, Probe.where(label: "tx").count
      assert_equal 0, DomainEvent.where(event_type: "probe_created@v1").count
    end
  end

  test "commit persists both the domain row and its event (I1.1b)" do
    in_tenant do
      ActiveRecord::Base.transaction do
        p = Probe.create!(tenant_id: @tenant.id, label: "committed")
        DomainEvents.publish(event_type: "probe_created@v1", aggregate: p, payload: {})
      end
      assert_equal 1, Probe.where(label: "committed").count
      assert_equal 1, DomainEvent.where(event_type: "probe_created@v1").count
    end
  end

  test "a fresh publisher delivers a committed but unpublished event (I1.1c)" do
    publish_one("probe_created@v1")
    delivered = []
    svc_outbox { OutboxPublisher.run(deliver: ->(e) { delivered << e.id }) }
    assert_equal 1, delivered.size
    svc_outbox { assert_equal 0, DomainEvent.unpublished.count }
  end

  test "two events for one aggregate get consecutive sequences (I1.3)" do
    in_tenant do
      ActiveRecord::Base.transaction do
        DomainEvents.publish(event_type: "a@v1", aggregate: @probe, payload: {})
        DomainEvents.publish(event_type: "b@v1", aggregate: @probe, payload: {})
      end
      assert_equal [ 1, 2 ], DomainEvent.where(aggregate_id: @probe.id).order(:sequence).pluck(:sequence)
    end
  end

  test "different aggregates get independent sequences — no global counter (I1.3)" do
    in_tenant do
      other = Probe.create!(tenant: @tenant, label: "other")
      ActiveRecord::Base.transaction do
        DomainEvents.publish(event_type: "a@v1", aggregate: @probe, payload: {})
        DomainEvents.publish(event_type: "a@v1", aggregate: other, payload: {})
      end
      assert_equal 1, DomainEvent.where(aggregate_id: @probe.id).first.sequence
      assert_equal 1, DomainEvent.where(aggregate_id: other.id).first.sequence
    end
  end

  test "a crash between deliver and mark causes redelivery (I1.4)" do
    publish_one("x@v1")
    delivered = []
    deliver = ->(e) { delivered << e.id }

    svc_outbox do
      assert_raises(RuntimeError) do
        OutboxPublisher.run(deliver: deliver, after_deliver: ->(_e) { raise "crash before mark" })
      end
    end
    svc_outbox { assert_equal 1, DomainEvent.unpublished.count, "still unpublished after the crash" }

    svc_outbox { OutboxPublisher.run(deliver: deliver) }
    assert_equal 2, delivered.size, "redelivered on the next run (at-least-once)"
    svc_outbox { assert_equal 0, DomainEvent.unpublished.count }
  end

  test "svc_outbox reads domain_events but zero rows from other tables (I1.5 / D4)" do
    publish_one("x@v1")
    svc_outbox do
      assert_equal 1, DomainEvent.count
      assert_equal 0, Probe.count, "svc_outbox is scoped to domain_events only"
    end
  end

  private

  def publish_one(type)
    in_tenant do
      ActiveRecord::Base.transaction do
        DomainEvents.publish(event_type: type, aggregate: @probe, payload: {})
      end
    end
  end

  def in_tenant
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end

  def svc_outbox
    Rls.set(scope_type: "svc_outbox", connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
