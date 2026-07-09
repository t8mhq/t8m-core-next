# S1-G1 · I1 — a minimal tenant-scoped table used to prove the policy shape.
# Not a domain table; it exists so the negative/positive RLS tests have a target
# from day one (the real domain tables adopt enable_tenant_rls the same way).
class CreateProbes < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :probes, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string :label
      t.timestamps
    end

    enable_tenant_rls :probes
  end
end
