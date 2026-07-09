require "test_helper"

# S1-G2 · I7 — retention with carve-out, as app_user.
class OutboxPrunerTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    @probe = Probe.create!(tenant: @tenant, label: "agg")
    Rls.reset(connection: conn)
  end

  teardown do
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    DomainEvent.where(tenant_id: @tenant.id).delete_all
    Probe.where(tenant_id: @tenant.id).delete_all
    Rls.reset(connection: conn)
    ArchivedEvent.delete_all
    Tenant.where(id: @tenant.id).delete_all
  end

  test "prunes old plain events, archives carve-out, keeps recent, alerts stale unpublished" do
    old_plain = publish("probe_touched@v1")
    backdate(old_plain, published_days: 100)
    old_fiscal = publish("fiscal_document_issued@v1")
    backdate(old_fiscal, published_days: 100)
    recent = publish("probe_touched@v1")
    backdate(recent, published_days: 1)
    stale_unpub = publish("probe_touched@v1")
    backdate(stale_unpub, occurred_days: 200) # published_at stays nil

    result = svc_outbox { OutboxPruner.run }

    assert_not exists?(old_plain), "old non-carve-out pruned (I7.1)"
    assert exists?(old_fiscal), "carve-out kept (I7.1)"
    assert exists?(recent), "recent kept"
    assert exists?(stale_unpub), "unpublished never pruned regardless of age (I7.2)"

    assert_equal 1, ArchivedEvent.where(event_id: old_fiscal.id).count, "carve-out archived before pruning"
    assert_includes result[:alerts], stale_unpub.id, "stale unpublished alerted, not pruned (I7.2)"
    assert_equal 1, result[:pruned]
    assert_equal 1, result[:archived]
  end

  private

  def publish(type)
    event = nil
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    ActiveRecord::Base.transaction { event = DomainEvents.publish(event_type: type, aggregate: @probe, payload: {}) }
    Rls.reset(connection: conn)
    event
  end

  def backdate(event, published_days: nil, occurred_days: nil)
    attrs = {}
    attrs[:published_at] = published_days.days.ago if published_days
    attrs[:occurred_at] = occurred_days.days.ago if occurred_days
    svc_outbox { DomainEvent.where(id: event.id).update_all(attrs) }
  end

  def exists?(event)
    svc_outbox { DomainEvent.exists?(event.id) }
  end

  def svc_outbox
    Rls.set(scope_type: "svc_outbox", connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
