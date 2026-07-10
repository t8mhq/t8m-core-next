require "test_helper"

# S1-G4 · I4 — split-rule construction, as app_user (mkt_platform for construction).
class PaymentsSplitTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @a = Tenant.create!(name: "Seller A")
    @b = Tenant.create!(name: "Seller B")
    @c = Tenant.create!(name: "Seller C (no recipient)")
    approve_recipient(@a)
    approve_recipient(@b)
  end

  teardown do
    [ @a, @b, @c ].each do |t|
      Rls.set(scope_type: "tenant", tenant_id: t.id, connection: conn)
      Payments::Recipient.where(tenant_id: t.id).delete_all
    end
    Rls.reset(connection: conn)
    Tenant.where(id: [ @a.id, @b.id, @c.id ]).delete_all
  end

  test "a split reconciles: sum(legs) + commission == total (property)" do
    as_platform do
      50.times do
        a = rand(1..10_000)
        b = rand(1..10_000)
        commission = rand(0..2_000)
        total = a + b + commission

        split = Payments::Api.build_split(
          total_cents: total, seller_amounts: { @a.id => a, @b.id => b }, commission_cents: commission
        )
        assert_equal total, split.legs.sum(&:amount_cents) + split.commission_cents
        assert_equal 2, split.legs.size
      end
    end
  end

  test "a non-reconciling split is refused" do
    as_platform do
      assert_raises(Payments::Split::NotReconciled) do
        Payments::Api.build_split(total_cents: 1000, seller_amounts: { @a.id => 400, @b.id => 400 }, commission_cents: 100)
      end
    end
  end

  test "a seller without an approved recipient cannot be targeted by a split (I4)" do
    as_platform do
      assert_raises(Payments::Split::SellerNotApproved) do
        Payments::Api.build_split(total_cents: 300, seller_amounts: { @a.id => 100, @c.id => 200 }, commission_cents: 0)
      end
    end
  end

  private

  def approve_recipient(tenant)
    Rls.set(scope_type: "tenant", tenant_id: tenant.id, connection: conn)
    Payments::Api.approve_recipient(Payments::Api.register_recipient)
  ensure
    Rls.reset(connection: conn)
  end

  def as_platform
    Rls.set(scope_type: "mkt_platform", connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end
end
