# S1-G2 · I5 — catalog reservations (packs/catalog): the columns that hurt to retrofit.
class CreateCatalogProducts < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :products, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.string :name, null: false
      t.integer :price_cents, null: false, default: 0
      t.integer :cost_cents               # reservation — nullable, integer cents
      t.string :ncm                       # reservation — NCM code
      t.timestamps
    end
    enable_tenant_rls :products

    # NCM registry (global; ST / monofásico flags). Model only, no data load.
    create_table :ncm_classifications, id: :uuid do |t|
      t.string :ncm, null: false
      t.boolean :st, null: false, default: false          # substituição tributária
      t.boolean :monofasico, null: false, default: false
      t.timestamps
    end
    add_index :ncm_classifications, :ncm, unique: true
  end
end
