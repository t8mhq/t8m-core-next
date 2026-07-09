SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: app_scope(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.app_scope() RETURNS text
    LANGUAGE sql STABLE
    AS $$ SELECT current_setting('app.scope_type', true) $$;


--
-- Name: app_tenant_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.app_tenant_id() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$ SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid $$;


--
-- Name: app_user_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.app_user_id() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$ SELECT NULLIF(current_setting('app.user_id', true), '')::uuid $$;


--
-- Name: granted_tenants(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.granted_tenants(uid uuid) RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$ SELECT grantor_tenant_id FROM access_grants
     WHERE grantee_user_id = uid AND revoked_at IS NULL $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_grants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    grantor_tenant_id uuid NOT NULL,
    grantee_user_id uuid NOT NULL,
    role character varying NOT NULL,
    revoked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.access_grants FORCE ROW LEVEL SECURITY;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: probes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.probes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    label character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.probes FORCE ROW LEVEL SECURITY;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    host character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: access_grants access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_grants
    ADD CONSTRAINT access_grants_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: probes probes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.probes
    ADD CONSTRAINT probes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: index_access_grants_on_grantee_user_id_and_revoked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_grants_on_grantee_user_id_and_revoked_at ON public.access_grants USING btree (grantee_user_id, revoked_at);


--
-- Name: index_access_grants_on_grantor_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_grants_on_grantor_tenant_id ON public.access_grants USING btree (grantor_tenant_id);


--
-- Name: index_probes_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_probes_on_tenant_id ON public.probes USING btree (tenant_id);


--
-- Name: index_tenants_on_host; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tenants_on_host ON public.tenants USING btree (host) WHERE (host IS NOT NULL);


--
-- Name: access_grants fk_rails_2c102d78ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_grants
    ADD CONSTRAINT fk_rails_2c102d78ae FOREIGN KEY (grantor_tenant_id) REFERENCES public.tenants(id);


--
-- Name: probes fk_rails_50bbc796a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.probes
    ADD CONSTRAINT fk_rails_50bbc796a2 FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: access_grants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.access_grants ENABLE ROW LEVEL SECURITY;

--
-- Name: probes grant_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY grant_read ON public.probes FOR SELECT USING (((public.app_scope() = 'grant'::text) AND (tenant_id IN ( SELECT public.granted_tenants(public.app_user_id()) AS granted_tenants))));


--
-- Name: access_grants grantee_reads_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY grantee_reads_own ON public.access_grants FOR SELECT USING (((public.app_scope() = 'grant'::text) AND (grantee_user_id = public.app_user_id())));


--
-- Name: access_grants grantor_manages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY grantor_manages ON public.access_grants USING (((public.app_scope() = 'tenant'::text) AND (grantor_tenant_id = public.app_tenant_id())));


--
-- Name: probes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.probes ENABLE ROW LEVEL SECURITY;

--
-- Name: probes tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.probes USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260709175653'),
('20260709140516'),
('20260709140515'),
('20260709140514');

