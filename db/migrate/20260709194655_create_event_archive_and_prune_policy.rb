# S1-G2 · I7 — retention: an archive table (stub target) + the svc_outbox DELETE policy
# the pruner needs (svc_outbox could already SELECT/UPDATE domain_events; pruning adds
# DELETE, still scoped to domain_events only).
class CreateEventArchiveAndPrunePolicy < ActiveRecord::Migration[8.1]
  def up
    create_table :archived_events, id: :uuid do |t|
      t.uuid :event_id, null: false
      t.string :event_type, null: false
      t.datetime :archived_at, null: false
    end
    add_index :archived_events, :event_id, unique: true

    execute <<~SQL
      CREATE POLICY svc_outbox_prune ON domain_events
        FOR DELETE USING (app_scope() = 'svc_outbox');
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS svc_outbox_prune ON domain_events;"
    drop_table :archived_events
  end
end
