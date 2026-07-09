require "test_helper"

# S1-G1 · I4 — the job runner guard.
class ScopedJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  self.use_transactional_tests = false

  # Requires scope, records whether perform ran, and queries a tenant-scoped table.
  class GuardedProbeJob < ApplicationJob
    requires_scope!
    class << self; attr_accessor :performed, :seen_count; end

    def perform(_tenant_id = nil)
      self.class.performed = true
      self.class.seen_count = Probe.count
    end

    def rls_scope
      (tid = arguments.first) ? { scope_type: "tenant", tenant_id: tid } : nil
    end
  end

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
    seed_probe(@tenant, "t1")
    GuardedProbeJob.performed = false
    GuardedProbeJob.seen_count = nil
  end

  teardown do
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    Probe.where(tenant_id: @tenant.id).delete_all
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "a scope-requiring job without scope raises before any SQL (I4.1)" do
    assert_raises(Rls::MissingScope) { GuardedProbeJob.perform_now }
    assert_not GuardedProbeJob.performed, "perform (and its SQL) must not run"
  end

  test "a job with scope runs and leaves no residual context (I4.2)" do
    GuardedProbeJob.perform_now(@tenant.id)
    assert GuardedProbeJob.performed
    assert_equal 1, GuardedProbeJob.seen_count, "job saw its tenant's rows"
    assert_nil Rls.current_scope(connection: conn), "no residual context after the job"
  end

  test "the guard fires on the adapter execution path (I4.3)" do
    # ActiveJob::Base.execute(serialized) is exactly what a Solid Queue worker calls
    # after deserializing a job — so the guard covers Solid Queue by construction.
    serialized = GuardedProbeJob.new.serialize # no args ⇒ no scope
    assert_raises(Rls::MissingScope) { ActiveJob::Base.execute(serialized) }
    assert_not GuardedProbeJob.performed, "guard runs regardless of the adapter path"
  end

  private

  def seed_probe(tenant, label)
    Rls.set(scope_type: "tenant", tenant_id: tenant.id, connection: conn)
    Probe.create!(tenant: tenant, label: label)
  ensure
    Rls.reset(connection: conn)
  end
end
