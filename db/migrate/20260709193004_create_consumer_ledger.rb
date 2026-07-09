# S1-G2 · I2 / D5 — the consumer idempotency ledger + a reference side-effect table.
# Both are service-level infra (no tenant_id ⇒ no tenant RLS): the ledger records
# "consumer X processed event Y" and the reference effect is an observable write used
# by the replay tests. The unique index is what makes replay a no-op.
class CreateConsumerLedger < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_events, id: :uuid do |t|
      t.string :consumer_name, null: false
      t.uuid :event_id, null: false
      t.datetime :processed_at, null: false
    end
    add_index :processed_events, %i[consumer_name event_id], unique: true,
      name: "idx_processed_events_uniqueness"

    create_table :consumer_effects, id: :uuid do |t|
      t.string :consumer_name, null: false
      t.uuid :event_id, null: false
      t.timestamps
    end
  end
end
