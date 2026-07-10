-- S1-G0 · D5 — Idempotent Postgres role provisioning for the Core.
--
-- Roles:
--   app_migrator : schema owner; runs migrations.
--   app_user     : runtime + test-suite connection.
--                  NOSUPERUSER NOBYPASSRLS — G1's RLS policies rely on app_user
--                  NOT being able to bypass row-level security.
--
-- G0 provisions the roles; G1 uses them (adds RLS policies enforced against app_user).
-- Invoked by bin/provision-db, which supplies :migrator_password and :user_password
-- and runs this as a Postgres superuser. Safe to run repeatedly.

\set ON_ERROR_STOP on

-- Create app_migrator only if absent (\gexec runs the generated statement).
SELECT format('CREATE ROLE app_migrator LOGIN CREATEDB PASSWORD %L', :'migrator_password')
 WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_migrator')\gexec

SELECT format('CREATE ROLE app_user LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD %L', :'user_password')
 WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user')\gexec

-- Re-assert the runtime role's safety attributes even if it pre-existed:
-- this is the invariant G1 depends on and must never drift.
ALTER ROLE app_user NOSUPERUSER NOBYPASSRLS;

-- S1-G5 · I4 — the IA satellite's role: reads the domain, NEVER writes core (ADR-0007).
-- SELECT is granted in bin/provision-db; write on ia_* is granted in db/grants.sql.
-- No write grant on core tables ⇒ "zero write paths to core" enforced by the DB role.
SELECT format('CREATE ROLE svc_ia LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD %L', :'ia_password')
 WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_ia')\gexec
ALTER ROLE svc_ia NOSUPERUSER NOBYPASSRLS;
