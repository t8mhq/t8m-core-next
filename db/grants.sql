-- S1-G2 · I4 / D7 — table-specific role grants/revokes.
--
-- pg_dump --no-privileges (Rails structure dump) strips ACLs, so these do NOT survive
-- in structure.sql. They are re-applied after every schema load by `rails db:grants`
-- (run as the owner, app_migrator). Idempotent.
--
-- stock_movements is append-only: the runtime role may INSERT/SELECT but never mutate.
REVOKE UPDATE, DELETE ON stock_movements FROM app_user;

-- S1-G5 · I4 — svc_ia may write its OWN read-model store (it has SELECT-only on core).
GRANT INSERT, UPDATE, DELETE ON ia_read_models TO svc_ia;
