require "test_helper"

# S1-G3 · I4 — the sync boundary through the full Rack stack (middleware sets the RLS
# scope from the device header), as app_user.
class SyncIntegrationTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
  end

  teardown do
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    SyncReceipt.where(tenant_id: @tenant.id).delete_all
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  def device_headers = { "X-Device-Tenant" => @tenant.id }

  test "up-sync is idempotent by POS UUID — replay returns 200 with the original result" do
    uuid = SecureRandom.uuid
    body = { sales: [ { uuid: uuid, occurred_at: Time.current.iso8601 } ] }

    post "/api/v1/sync/sales", params: body, as: :json, headers: device_headers
    assert_response :success
    assert_equal "processed", response.parsed_body["results"].first["status"]

    post "/api/v1/sync/sales", params: body, as: :json, headers: device_headers
    assert_response :success
    assert_equal "replayed", response.parsed_body["results"].first["status"], "replay is idempotent"

    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    assert_equal 1, SyncReceipt.where(uuid: uuid).count, "exactly one receipt"
    Rls.reset(connection: conn)
  end

  test "without a device token the sync boundary is unauthorized (default deny)" do
    post "/api/v1/sync/sales", params: { sales: [] }, as: :json
    assert_response :unauthorized
  end

  test "down-sync returns a snapshot with contract_version + typed config" do
    get "/api/v1/sync/down", params: { updated_since: 1.day.ago.iso8601 }, headers: device_headers
    assert_response :success
    body = response.parsed_body
    assert_equal "1.0.0", body["contract_version"]
    assert body.key?("config")
    assert body.key?("promotion_ruleset_version")
  end
end
