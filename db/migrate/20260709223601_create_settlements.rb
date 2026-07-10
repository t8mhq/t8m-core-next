# S1-G4 · I5+I6 — settlement facts per leg (ADR-0005 §settlement facts, §fee capture).
# Pagar.me settles each recipient directly; the platform ingests the facts (amount, the
# effective acquirer fee, payout date) as the seller's settlements — fee_cents is the
# margin-intelligence input (ADR-0007). Tenant-scoped to the seller.
class CreateSettlements < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :settlements, id: :uuid do |t|
      t.uuid :tenant_id, null: false               # the seller tenant
      t.string :gateway_charge_id, null: false
      t.integer :amount_cents, null: false          # settled to the seller (this leg)
      t.integer :fee_cents, null: false, default: 0 # effective acquirer/gateway fee
      t.date :payout_date
      t.timestamps
    end
    add_index :settlements, %i[tenant_id gateway_charge_id]
    enable_tenant_rls :settlements
  end
end
