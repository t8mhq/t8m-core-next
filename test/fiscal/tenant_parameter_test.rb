require "test_helper"

# S1-G2 · I5 / D8 — temporal fiscal parameters, as app_user.
class FiscalTenantParameterTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
  end

  teardown do
    in_scope { Fiscal::TenantParameter.where(tenant_id: @tenant.id).delete_all }
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "overlapping validity ranges for one tenant are rejected (I5.1 / D8)" do
    in_scope do
      param(from: "2026-01-01", to: "2026-06-01", rate: 400)
      assert_raises(ActiveRecord::StatementInvalid) do
        param(from: "2026-03-01", to: "2026-09-01", rate: 500) # overlaps Jan–Jun
      end
    end
  end

  test "adjacent [) ranges do not overlap and are allowed" do
    in_scope do
      param(from: "2026-01-01", to: "2026-02-01", rate: 400)
      assert param(from: "2026-02-01", to: "2026-03-01", rate: 500).persisted?
    end
  end

  test "parameters_at returns the row in force across boundary dates (I5.2)" do
    in_scope do
      jan = param(from: "2026-01-01", to: "2026-02-01", rate: 400)
      feb = param(from: "2026-02-01", to: nil, rate: 500) # open-ended

      assert_equal jan.id, at("2026-01-15").id
      assert_equal jan.id, at("2026-01-31").id, "last day of Jan still in force"
      assert_equal feb.id, at("2026-02-01").id, "boundary belongs to the later range ([) )"
      assert_equal feb.id, at("2026-06-01").id, "open-ended range covers the future"
      assert_nil at("2025-12-31"), "before any range → nil"
    end
  end

  private

  def param(from:, to:, rate:)
    Fiscal::TenantParameter.create!(
      tenant_id: @tenant.id, rate_bps: rate, annex: "I",
      valid_from: Date.parse(from), valid_to: (to && Date.parse(to))
    )
  end

  def at(date) = Fiscal::TenantParameter.parameters_at(@tenant.id, Date.parse(date))

  def in_scope
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
