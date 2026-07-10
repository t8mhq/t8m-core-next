# S1-G2 · I4 — nightly stock reconciliation. Iterates tenants (the registry is not
# RLS-scoped), runs the alert-only reconciliation under each tenant's scope, and logs
# divergences. Never corrects.
class StockReconciliationJob < ApplicationJob
  def perform
    Tenant.pluck(:id).each do |tenant_id|
      Rls.with_scope(scope_type: "tenant", tenant_id: tenant_id) do
        Stock::Api.reconcile.each do |divergence|
          Rails.logger.warn("[stock] divergence tenant=#{tenant_id} #{divergence.to_h}")
        end
      end
    end
  end
end
