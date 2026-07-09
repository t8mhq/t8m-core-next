# S1-G1 · I1 — the context resolution seam.
#
# Real resolution paths, stubbed token machinery (per gate scope):
#   * POS: device-token claim → tenant — the seam exists; issuance/verification is a
#     later stage, so the claim is read from a header for now.
#   * storefront: Host header → tenant (via the tenants registry, read WITHOUT context
#     since `tenants` is intentionally not tenant-scoped).
#
# Returns a context hash for Rls.set, or nil (⇒ default-deny for that request).
module RlsContextResolver
  module_function

  def call(env)
    req = ActionDispatch::Request.new(env)

    if (tenant_id = pos_device_tenant(req))
      { scope_type: "tenant", tenant_id: tenant_id, user_id: req.get_header("HTTP_X_USER_ID") }
    elsif (tenant = storefront_tenant(req))
      { scope_type: "tenant", tenant_id: tenant.id }
    end
  end

  # Stubbed device-token path: a real pairing/verification flow lands in a later stage.
  def pos_device_tenant(req)
    req.get_header("HTTP_X_DEVICE_TENANT").presence
  end

  def storefront_tenant(req)
    host = req.host.to_s
    return if host.empty?

    Tenant.find_by(host: host)
  end
end
