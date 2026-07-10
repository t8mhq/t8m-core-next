# S1-G3 · I4 — idempotency receipts for the POS sync boundary. A batch upsert keyed by
# POS UUID: the first time a uuid is seen it is processed; a replay returns the original
# result (at-least-once with idempotent 200 replays, ADR-0009). Tenant-scoped.
class CreateSyncReceipts < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :sync_receipts, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.uuid :uuid, null: false           # the POS-generated idempotency key
      t.jsonb :result, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :sync_receipts, %i[tenant_id uuid], unique: true
    enable_tenant_rls :sync_receipts
  end
end
