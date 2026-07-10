# S1-G4 · I3 — every approved seller is a Pagar.me recipient (ADR-0005). KYC status
# gates seller activation (ADR-0004) and split targeting (I4). Tenant-scoped (the seller
# sees its own) plus a mkt_platform read policy so split construction can verify approval.
class CreatePagarmeRecipients < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def up
    create_table :pagarme_recipients, id: :uuid do |t|
      t.uuid :tenant_id, null: false                 # the seller tenant
      t.string :recipient_id                         # Pagar.me recipient id
      t.string :kyc_status, null: false, default: "pending" # pending | approved | refused
      t.timestamps
    end
    add_index :pagarme_recipients, :tenant_id, unique: true
    enable_tenant_rls :pagarme_recipients

    execute <<~SQL
      CREATE POLICY mkt_platform_read ON pagarme_recipients
        FOR SELECT USING (app_scope() = 'mkt_platform');
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS mkt_platform_read ON pagarme_recipients;"
    drop_table :pagarme_recipients
  end
end
