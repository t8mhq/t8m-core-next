# S1-G1 · I1 — the tenant registry.
#
# Deliberately NOT tenant-scoped: context resolution (host/device-token → tenant)
# must read this table BEFORE any tenant context exists. It is the registry, not
# tenant-owned data. Rows here are non-sensitive identity records.
class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants, id: :uuid do |t|
      t.string :name, null: false
      t.string :host                      # storefront host — part of the resolution seam
      t.timestamps
    end
    add_index :tenants, :host, unique: true, where: "host IS NOT NULL"
  end
end
