# S1-G2 · I4 / D7 — immutable stock_movements + derived stock_balances (packs/stock).
class CreateStockMovements < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def up
    create_table :stock_movements, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.uuid :product_id, null: false
      t.integer :delta, null: false       # signed: +in / -out
      t.string :reason
      t.datetime :created_at, null: false
    end
    enable_tenant_rls :stock_movements

    create_table :stock_balances, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.uuid :product_id, null: false
      t.integer :balance, null: false, default: 0
      t.timestamps
    end
    add_index :stock_balances, %i[tenant_id product_id], unique: true
    enable_tenant_rls :stock_balances

    # D7 — immutability, two independent defenses:
    #   1. REVOKE mutation from the runtime role (primary).
    #   2. A trigger that blocks UPDATE/DELETE for ANY role, incl. a future careless
    #      GRANT or the table owner (belt-and-suspenders).
    execute <<~SQL
      REVOKE UPDATE, DELETE ON stock_movements FROM app_user;

      CREATE FUNCTION stock_movements_immutable() RETURNS trigger LANGUAGE plpgsql AS $fn$
      BEGIN
        RAISE EXCEPTION 'stock_movements are append-only (immutable)';
      END;
      $fn$;

      CREATE TRIGGER stock_movements_no_mutate
        BEFORE UPDATE OR DELETE ON stock_movements
        FOR EACH ROW EXECUTE FUNCTION stock_movements_immutable();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS stock_movements_no_mutate ON stock_movements;
      DROP FUNCTION IF EXISTS stock_movements_immutable();
    SQL
    drop_table :stock_balances
    drop_table :stock_movements
  end
end
