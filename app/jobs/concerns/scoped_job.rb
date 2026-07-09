# S1-G1 · I4 — job runner guard.
#
# A job that touches tenant-scoped data must run within an RLS scope. Jobs that
# declare `requires_scope!` and do not supply one raise Rls::MissingScope in an
# around_perform callback — BEFORE perform runs, so no SQL executes without scope.
# When a scope is supplied it is established transaction-locally (Rls.with_scope),
# so the context provably vanishes when the job finishes (no residue).
module ScopedJob
  extend ActiveSupport::Concern

  included do
    class_attribute :requires_scope, instance_writer: false, default: false
    around_perform :run_within_rls_scope
  end

  class_methods do
    def requires_scope!
      self.requires_scope = true
    end
  end

  private

  def run_within_rls_scope
    scope = rls_scope

    if requires_scope && scope.blank?
      raise Rls::MissingScope, "#{self.class.name} must run within an RLS scope"
    end

    if scope.present?
      Rls.with_scope(**scope.symbolize_keys) { yield }
    else
      yield
    end
  end

  # Override to derive the scope hash ({ scope_type:, tenant_id:, user_id: }) from the
  # job's arguments. Returns nil when there is no scope.
  def rls_scope
    nil
  end
end
