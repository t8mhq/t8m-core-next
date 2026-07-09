require "test_helper"

# S1-G2 · I6 — the one flag idiom + governance, as app_user.
class FeatureTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T", plan: "pro")
  end

  teardown do
    in_scope { TenantFeatureOverride.where(tenant_id: @tenant.id).delete_all }
    PlanEntitlement.delete_all
    conn.execute("DELETE FROM flipper_gates")
    conn.execute("DELETE FROM flipper_features")
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "override beats plan: plan no + override yes ⇒ yes (I6.1)" do
    PlanEntitlement.create!(plan: "pro", feature_key: "x", enabled: false)
    in_scope do
      TenantFeatureOverride.create!(tenant_id: @tenant.id, feature_key: "x", enabled: true)
      assert Feature.enabled?(:x, tenant: @tenant)
    end
  end

  test "override beats plan: plan yes + override no ⇒ no (I6.1 inverse)" do
    PlanEntitlement.create!(plan: "pro", feature_key: "x", enabled: true)
    in_scope do
      TenantFeatureOverride.create!(tenant_id: @tenant.id, feature_key: "x", enabled: false)
      assert_not Feature.enabled?(:x, tenant: @tenant)
    end
  end

  test "plan applies when there is no override" do
    PlanEntitlement.create!(plan: "pro", feature_key: "y", enabled: true)
    in_scope { assert Feature.enabled?(:y, tenant: @tenant) }
  end

  test "flag default applies when neither plan nor override match" do
    in_scope do
      assert_not Feature.enabled?(:z, tenant: @tenant)
      Flipper.enable(:z)
      assert Feature.enabled?(:z, tenant: @tenant)
    end
  end

  test "a release flag without owner + expiry is invalid (I6.2)" do
    flag = FeatureFlag.new(key: "r", kind: "release")
    assert_not flag.valid?
    assert_includes flag.errors.attribute_names, :owner
    assert_includes flag.errors.attribute_names, :expires_at

    flag.owner = "growth-team"
    flag.expires_at = 30.days.from_now
    assert flag.valid?, flag.errors.full_messages.to_sentence
  end

  private

  def in_scope
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
