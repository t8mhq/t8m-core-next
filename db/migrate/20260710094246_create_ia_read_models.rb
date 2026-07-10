# S1-G5 · I4 — the IA satellite's own read-model store (ADR-0007). Service-level: NOT a
# core table, and svc_ia may write HERE (grants.sql) but never to core. The subject
# column is named subject_tenant_id (not tenant_id) — this is the satellite's projection,
# not tenant-owned core data.
class CreateIaReadModels < ActiveRecord::Migration[8.1]
  def change
    create_table :ia_read_models, id: :uuid do |t|
      t.string :kind, null: false
      t.uuid :subject_tenant_id
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
    add_index :ia_read_models, %i[kind subject_tenant_id]
  end
end
