# S1-G2 · I1 — the transactional outbox (ADR-0002).
class CreateDomainEvents < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :domain_events, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.string :aggregate_type, null: false
      t.uuid :aggregate_id, null: false
      t.bigint :sequence, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.datetime :published_at
    end

    # D2 — per-aggregate sequence is unique.
    add_index :domain_events, %i[aggregate_type aggregate_id sequence],
      unique: true, name: "idx_domain_events_aggregate_sequence"
    # D3 — the publisher scans unpublished rows in order.
    add_index :domain_events, %i[aggregate_type aggregate_id sequence],
      where: "published_at IS NULL", name: "idx_domain_events_unpublished"

    # D4 — outbox rows are tenant-scoped like everything else (writers use tenant scope)...
    enable_tenant_rls :domain_events

    # ...plus a svc_outbox service scope: SELECT/UPDATE on domain_events ONLY (same shape
    # as mkt_platform — no policy names svc_outbox on any other table, so it reads zero
    # rows elsewhere). The publisher job runs under svc_outbox via the G1 job guard.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE POLICY svc_outbox_read ON domain_events
            FOR SELECT USING (app_scope() = 'svc_outbox');
          CREATE POLICY svc_outbox_mark ON domain_events
            FOR UPDATE USING (app_scope() = 'svc_outbox');
        SQL
      end
      dir.down do
        execute <<~SQL
          DROP POLICY IF EXISTS svc_outbox_read ON domain_events;
          DROP POLICY IF EXISTS svc_outbox_mark ON domain_events;
        SQL
      end
    end
  end
end
