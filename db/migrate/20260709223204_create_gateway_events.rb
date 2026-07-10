# S1-G4 · I2 — webhook idempotency ledger (ADR-0005 §webhook truth). Confirmation of
# online/marketplace payments is webhook-only; each gateway event is recorded once
# (unique gateway_event_id) and processed via the queue, never inline. Service-level.
class CreateGatewayEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :gateway_events, id: :uuid do |t|
      t.string :gateway_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :received_at, null: false
      t.datetime :processed_at
    end
    add_index :gateway_events, :gateway_event_id, unique: true
  end
end
