# S1-G2 · I6 — the ONE flag idiom. Resolution (most specific wins):
#   per-tenant override → plan entitlement → flag default (Flipper).
# Called only at controller/service boundaries (bin/lint-flag-usage keeps it that way).
module Feature
  module_function

  def enabled?(key, tenant:)
    key = key.to_s

    override = TenantFeatureOverride.find_by(tenant_id: tenant.id, feature_key: key)
    return override.enabled unless override.nil?

    entitlement = PlanEntitlement.find_by(plan: tenant.plan, feature_key: key)
    return entitlement.enabled unless entitlement.nil?

    Flipper.enabled?(key)
  end
end
