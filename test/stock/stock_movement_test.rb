require "test_helper"
require "pg"

# S1-G2 · I4 — immutable stock_movements + derived balance, as app_user.
class StockMovementTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "T")
    @product = SecureRandom.uuid
  end

  teardown do
    # No stock cleanup: movements are immutable (DELETE is blocked) and tenant-isolated,
    # and every test uses a fresh @tenant, so leftover rows are invisible. (A TRUNCATE
    # here takes an ACCESS EXCLUSIVE lock that contends with the shared test connection.)
    in_scope { DomainEvent.where(tenant_id: @tenant.id).delete_all }
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "record_movement appends a movement, upserts balance, publishes stock_moved" do
    in_scope do
      movement = Stock::Api.record_movement(product_id: @product, delta: 10, reason: "purchase")
      assert movement.persisted?
      assert_equal 10, Stock::Balance.find_by(product_id: @product).balance

      Stock::Api.record_movement(product_id: @product, delta: -3)
      assert_equal 7, Stock::Balance.find_by(product_id: @product).balance
      assert_equal 2, DomainEvent.where(event_type: "stock_moved@v1").count
    end
  end

  test "app_user cannot UPDATE or DELETE movements — revoke defense (I4.1)" do
    in_scope { Stock::Api.record_movement(product_id: @product, delta: 5) }
    in_scope do
      id = Stock::Movement.first.id
      assert_raises(ActiveRecord::StatementInvalid) { Stock::Movement.where(id: id).update_all(delta: 0) }
      assert_raises(ActiveRecord::StatementInvalid) { Stock::Movement.where(id: id).delete_all }
    end
  end

  test "the trigger blocks mutation even for the owner — trigger defense (I4.1)" do
    in_scope { Stock::Api.record_movement(product_id: @product, delta: 5) }
    id = in_scope { Stock::Movement.first.id }

    # app_migrator (owner) is NOT blocked by the REVOKE but IS blocked by the trigger.
    err = assert_raises(PG::Error) { migrator_exec("UPDATE stock_movements SET delta = 0 WHERE id = '#{id}'") }
    assert_match(/immutable/, err.message)
    err2 = assert_raises(PG::Error) { migrator_exec("DELETE FROM stock_movements WHERE id = '#{id}'") }
    assert_match(/immutable/, err2.message)
  end

  test "reconciliation detects an induced divergence and alerts without fixing (I4.3)" do
    in_scope do
      Stock::Api.record_movement(product_id: @product, delta: 8)
      Stock::Balance.where(product_id: @product).update_all(balance: 999) # corrupt the derived balance

      divergences = Stock::Api.reconcile
      assert_equal 1, divergences.size
      assert_equal 8, divergences.first.expected
      assert_equal 999, divergences.first.actual
      assert_equal 999, Stock::Balance.find_by(product_id: @product).balance, "reconciliation must not fix"
    end
  end

  private

  def in_scope
    Rls.set(scope_type: "tenant", tenant_id: @tenant.id, connection: conn)
    yield
  ensure
    Rls.reset(connection: conn)
  end

  def migrator_exec(sql, tenant: @tenant)
    db = ActiveRecord::Base.connection_db_config.configuration_hash
    pg = PG.connect(
      host: db[:host] || "localhost", port: db[:port] || 5432,
      user: "app_migrator", password: ENV.fetch("APP_MIGRATOR_PASSWORD", "app_migrator"),
      dbname: db[:database]
    )
    # FORCE RLS subjects the owner too — set a tenant context so the row is visible and
    # the TRIGGER (not RLS) is what blocks the mutation.
    if tenant
      pg.exec("SET app.scope_type = 'tenant'")
      pg.exec("SET app.tenant_id = '#{tenant.id}'")
    end
    pg.exec(sql)
  ensure
    pg&.close
  end
end
