# S1-G4 · I1 — a payment row becomes a gateway charge (ADR-0005). Confirmation is
# webhook-only (I2); creation records the gateway charge id + initial status.
class AddChargeFieldsToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :gateway_charge_id, :string
    add_column :payments, :status, :string, null: false, default: "awaiting_payment"
    add_index :payments, :gateway_charge_id, unique: true, where: "gateway_charge_id IS NOT NULL"
  end
end
