module Fiscal
  # S1-G5 — the fiscal pack public API. Fiscal readiness (ADR-0006) gates seller
  # activation (marketplace) without exposing the pack's private models.
  module Api
    module_function

    # A tenant is fiscally ready when it has fiscal parameters in force on `date`.
    # Read in the current tenant scope.
    def ready?(tenant_id, date = Date.current)
      Fiscal::TenantParameter.parameters_at(tenant_id, date).present?
    end
  end
end
