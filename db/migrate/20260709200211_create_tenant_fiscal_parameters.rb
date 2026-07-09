# S1-G2 · I5 / D8 — temporal fiscal parameters (packs/fiscal), overlap-proof at the
# schema level: two overlapping validity ranges for one tenant are UNREPRESENTABLE.
class CreateTenantFiscalParameters < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def up
    enable_extension "btree_gist" unless extension_enabled?("btree_gist")

    create_table :tenant_fiscal_parameters, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.integer :rate_bps, null: false               # Simples rate in basis points
      t.string :annex, null: false
      t.date :valid_from, null: false
      t.date :valid_to                               # null = open-ended
      t.string :authorship, null: false, default: "merchant_unverified" # accountant | merchant_unverified
      t.timestamps
    end
    enable_tenant_rls :tenant_fiscal_parameters

    execute <<~SQL
      ALTER TABLE tenant_fiscal_parameters
        ADD CONSTRAINT no_overlapping_validity
        EXCLUDE USING gist (
          tenant_id WITH =,
          daterange(valid_from, valid_to, '[)') WITH &&
        );
    SQL
  end

  def down
    execute "ALTER TABLE tenant_fiscal_parameters DROP CONSTRAINT IF EXISTS no_overlapping_validity;"
    drop_table :tenant_fiscal_parameters
  end
end
