# S1-G2 · I6 — flags + entitlements behind one idiom (ADR-0001 §flag discipline).
class CreateFlagsAndEntitlements < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    # Flipper ActiveRecord adapter tables (the flag DEFAULT layer).
    create_table :flipper_features do |t|
      t.string :key, null: false
      t.timestamps
    end
    add_index :flipper_features, :key, unique: true

    create_table :flipper_gates do |t|
      t.string :feature_key, null: false
      t.string :key, null: false
      t.string :value
      t.timestamps
    end
    add_index :flipper_gates, %i[feature_key key value], unique: true

    # Governance metadata: release flags must carry owner + expiry (validated in-model).
    create_table :feature_flags, id: :uuid do |t|
      t.string :key, null: false
      t.string :kind, null: false, default: "ops" # release | ops | experiment | permission
      t.string :owner
      t.datetime :expires_at
      t.timestamps
    end
    add_index :feature_flags, :key, unique: true

    # Plan → feature entitlement (global config; not tenant data).
    create_table :plan_entitlements, id: :uuid do |t|
      t.string :plan, null: false
      t.string :feature_key, null: false
      t.boolean :enabled, null: false, default: false
      t.timestamps
    end
    add_index :plan_entitlements, %i[plan feature_key], unique: true

    # Per-tenant override (tenant data ⇒ RLS).
    create_table :tenant_feature_overrides, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.string :feature_key, null: false
      t.boolean :enabled, null: false
      t.timestamps
    end
    add_index :tenant_feature_overrides, %i[tenant_id feature_key], unique: true
    enable_tenant_rls :tenant_feature_overrides

    add_column :tenants, :plan, :string, null: false, default: "free"
  end
end
