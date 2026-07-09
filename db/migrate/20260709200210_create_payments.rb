# S1-G2 · I5 — payments reservations (packs/payments). acquirer_fee_cents is enriched
# asynchronously (F7), so it is nullable now but must exist before any payment writes.
class CreatePayments < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :payments, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.string :provider                  # paygo | pagarme
      t.string :method
      t.integer :amount_cents, null: false, default: 0
      t.integer :acquirer_fee_cents       # reservation — nullable, integer cents
      t.timestamps
    end
    enable_tenant_rls :payments
  end
end
