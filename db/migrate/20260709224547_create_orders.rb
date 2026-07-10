# S1-G5 · I2 — orders (packs/orders). One order model for every channel (counter,
# online, marketplace, ADR-0004). Marketplace sub-orders materialize here in the seller's
# tenant through the public API — same table, same lifecycle. Tenant-scoped.
class CreateOrders < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :orders, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.string :channel, null: false           # counter | online | marketplace
      t.uuid :marketplace_order_ref            # set for marketplace sub-orders
      t.integer :total_cents, null: false, default: 0
      t.string :status, null: false, default: "confirmed"
      t.timestamps
    end
    add_index :orders, %i[tenant_id marketplace_order_ref]
    enable_tenant_rls :orders
  end
end
