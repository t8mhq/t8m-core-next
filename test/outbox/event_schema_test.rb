require "test_helper"

# S1-G2 · I3 — payload validation on publish, as app_user.
class EventSchemaTest < ActiveSupport::TestCase
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
    Tenant.where(id: @tenant.id).delete_all
  end

  test "a payload that violates its schema raises (I3.2)" do
    assert_raises(EventSchema::Invalid) do
      publish("order_placed@v1", { order_id: 123 }) # wrong type + missing total_cents
    end
  end

  test "an undeclared extra field is rejected (additionalProperties false)" do
    assert_raises(EventSchema::Invalid) do
      publish("order_placed@v1", { order_id: "o1", total_cents: 500, surprise: true })
    end
  end

  test "a valid payload publishes (I3.2 positive)" do
    assert publish("order_placed@v1", { order_id: "o1", total_cents: 500 }).persisted?
  end

  test "@v2 exists alongside @v1 and each validates independently (I3.3)" do
    assert EventSchema.registered?("order_placed@v1")
    assert EventSchema.registered?("order_placed@v2")
    assert publish("order_placed@v1", { order_id: "o1", total_cents: 500 }).persisted?
    assert publish("order_placed@v2", { order_id: "o2", total_cents: 900, coupon_code: "X" }).persisted?
  end

  test "unregistered event types skip validation (Stage-1 posture)" do
    assert publish("probe_touched@v1", { anything: 1 }).persisted?
  end

  private

  def publish(type, payload)
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    ActiveRecord::Base.transaction do
      DomainEvents.publish(event_type: type, aggregate: @probe, payload: payload)
    end
  ensure
    Rls.reset(connection: conn)
  end
end
