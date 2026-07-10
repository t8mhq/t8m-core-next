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
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


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


--
-- Name: stock_movements_immutable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stock_movements_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'stock_movements are append-only (immutable)';
END;
$$;


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
-- Name: archived_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    event_type character varying NOT NULL,
    archived_at timestamp(6) without time zone NOT NULL
);


--
-- Name: consumer_effects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consumer_effects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    consumer_name character varying NOT NULL,
    event_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: domain_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domain_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    aggregate_type character varying NOT NULL,
    aggregate_id uuid NOT NULL,
    sequence bigint NOT NULL,
    event_type character varying NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp(6) without time zone NOT NULL,
    published_at timestamp(6) without time zone
);

ALTER TABLE ONLY public.domain_events FORCE ROW LEVEL SECURITY;


--
-- Name: feature_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feature_flags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key character varying NOT NULL,
    kind character varying DEFAULT 'ops'::character varying NOT NULL,
    owner character varying,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: marketplace_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    seller_tenant_id uuid NOT NULL,
    buyer_id uuid,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.marketplace_orders FORCE ROW LEVEL SECURITY;


--
-- Name: ncm_classifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ncm_classifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ncm character varying NOT NULL,
    st boolean DEFAULT false NOT NULL,
    monofasico boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pagarme_recipients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagarme_recipients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    recipient_id character varying,
    kyc_status character varying DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.pagarme_recipients FORCE ROW LEVEL SECURITY;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    provider character varying,
    method character varying,
    amount_cents integer DEFAULT 0 NOT NULL,
    acquirer_fee_cents integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    gateway_charge_id character varying,
    status character varying DEFAULT 'awaiting_payment'::character varying NOT NULL
);

ALTER TABLE ONLY public.payments FORCE ROW LEVEL SECURITY;


--
-- Name: plan_entitlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plan_entitlements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan character varying NOT NULL,
    feature_key character varying NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
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
-- Name: processed_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.processed_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    consumer_name character varying NOT NULL,
    event_id uuid NOT NULL,
    processed_at timestamp(6) without time zone NOT NULL
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    name character varying NOT NULL,
    price_cents integer DEFAULT 0 NOT NULL,
    cost_cents integer,
    ncm character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.products FORCE ROW LEVEL SECURITY;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: seller_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seller_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    seller_tenant_id uuid NOT NULL,
    listing_status character varying DEFAULT 'draft'::character varying NOT NULL,
    display_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.seller_profiles FORCE ROW LEVEL SECURITY;


--
-- Name: stock_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_balances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    product_id uuid NOT NULL,
    balance integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.stock_balances FORCE ROW LEVEL SECURITY;


--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_movements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    product_id uuid NOT NULL,
    delta integer NOT NULL,
    reason character varying,
    created_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.stock_movements FORCE ROW LEVEL SECURITY;


--
-- Name: sync_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_receipts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    uuid uuid NOT NULL,
    result jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.sync_receipts FORCE ROW LEVEL SECURITY;


--
-- Name: tenant_feature_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_feature_overrides (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    feature_key character varying NOT NULL,
    enabled boolean NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.tenant_feature_overrides FORCE ROW LEVEL SECURITY;


--
-- Name: tenant_fiscal_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_fiscal_parameters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    rate_bps integer NOT NULL,
    annex character varying NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    authorship character varying DEFAULT 'merchant_unverified'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.tenant_fiscal_parameters FORCE ROW LEVEL SECURITY;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    host character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    plan character varying DEFAULT 'free'::character varying NOT NULL
);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


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
-- Name: archived_events archived_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_events
    ADD CONSTRAINT archived_events_pkey PRIMARY KEY (id);


--
-- Name: consumer_effects consumer_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumer_effects
    ADD CONSTRAINT consumer_effects_pkey PRIMARY KEY (id);


--
-- Name: domain_events domain_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domain_events
    ADD CONSTRAINT domain_events_pkey PRIMARY KEY (id);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (id);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: marketplace_orders marketplace_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_orders
    ADD CONSTRAINT marketplace_orders_pkey PRIMARY KEY (id);


--
-- Name: ncm_classifications ncm_classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ncm_classifications
    ADD CONSTRAINT ncm_classifications_pkey PRIMARY KEY (id);


--
-- Name: tenant_fiscal_parameters no_overlapping_validity; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_fiscal_parameters
    ADD CONSTRAINT no_overlapping_validity EXCLUDE USING gist (tenant_id WITH =, daterange(valid_from, valid_to, '[)'::text) WITH &&);


--
-- Name: pagarme_recipients pagarme_recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagarme_recipients
    ADD CONSTRAINT pagarme_recipients_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: plan_entitlements plan_entitlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_entitlements
    ADD CONSTRAINT plan_entitlements_pkey PRIMARY KEY (id);


--
-- Name: probes probes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.probes
    ADD CONSTRAINT probes_pkey PRIMARY KEY (id);


--
-- Name: processed_events processed_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processed_events
    ADD CONSTRAINT processed_events_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: seller_profiles seller_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seller_profiles
    ADD CONSTRAINT seller_profiles_pkey PRIMARY KEY (id);


--
-- Name: stock_balances stock_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_balances
    ADD CONSTRAINT stock_balances_pkey PRIMARY KEY (id);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: sync_receipts sync_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_receipts
    ADD CONSTRAINT sync_receipts_pkey PRIMARY KEY (id);


--
-- Name: tenant_feature_overrides tenant_feature_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_feature_overrides
    ADD CONSTRAINT tenant_feature_overrides_pkey PRIMARY KEY (id);


--
-- Name: tenant_fiscal_parameters tenant_fiscal_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_fiscal_parameters
    ADD CONSTRAINT tenant_fiscal_parameters_pkey PRIMARY KEY (id);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: idx_domain_events_aggregate_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_domain_events_aggregate_sequence ON public.domain_events USING btree (aggregate_type, aggregate_id, sequence);


--
-- Name: idx_domain_events_unpublished; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_domain_events_unpublished ON public.domain_events USING btree (aggregate_type, aggregate_id, sequence) WHERE (published_at IS NULL);


--
-- Name: idx_processed_events_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_processed_events_uniqueness ON public.processed_events USING btree (consumer_name, event_id);


--
-- Name: index_access_grants_on_grantee_user_id_and_revoked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_grants_on_grantee_user_id_and_revoked_at ON public.access_grants USING btree (grantee_user_id, revoked_at);


--
-- Name: index_access_grants_on_grantor_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_grants_on_grantor_tenant_id ON public.access_grants USING btree (grantor_tenant_id);


--
-- Name: index_archived_events_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_archived_events_on_event_id ON public.archived_events USING btree (event_id);


--
-- Name: index_feature_flags_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_feature_flags_on_key ON public.feature_flags USING btree (key);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_marketplace_orders_on_seller_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marketplace_orders_on_seller_tenant_id ON public.marketplace_orders USING btree (seller_tenant_id);


--
-- Name: index_ncm_classifications_on_ncm; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ncm_classifications_on_ncm ON public.ncm_classifications USING btree (ncm);


--
-- Name: index_pagarme_recipients_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pagarme_recipients_on_tenant_id ON public.pagarme_recipients USING btree (tenant_id);


--
-- Name: index_payments_on_gateway_charge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payments_on_gateway_charge_id ON public.payments USING btree (gateway_charge_id) WHERE (gateway_charge_id IS NOT NULL);


--
-- Name: index_plan_entitlements_on_plan_and_feature_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plan_entitlements_on_plan_and_feature_key ON public.plan_entitlements USING btree (plan, feature_key);


--
-- Name: index_probes_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_probes_on_tenant_id ON public.probes USING btree (tenant_id);


--
-- Name: index_seller_profiles_on_seller_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_seller_tenant_id ON public.seller_profiles USING btree (seller_tenant_id);


--
-- Name: index_stock_balances_on_tenant_id_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stock_balances_on_tenant_id_and_product_id ON public.stock_balances USING btree (tenant_id, product_id);


--
-- Name: index_sync_receipts_on_tenant_id_and_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sync_receipts_on_tenant_id_and_uuid ON public.sync_receipts USING btree (tenant_id, uuid);


--
-- Name: index_tenant_feature_overrides_on_tenant_id_and_feature_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tenant_feature_overrides_on_tenant_id_and_feature_key ON public.tenant_feature_overrides USING btree (tenant_id, feature_key);


--
-- Name: index_tenants_on_host; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tenants_on_host ON public.tenants USING btree (host) WHERE (host IS NOT NULL);


--
-- Name: stock_movements stock_movements_no_mutate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER stock_movements_no_mutate BEFORE DELETE OR UPDATE ON public.stock_movements FOR EACH ROW EXECUTE FUNCTION public.stock_movements_immutable();


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
-- Name: seller_profiles fk_rails_645bffefa3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seller_profiles
    ADD CONSTRAINT fk_rails_645bffefa3 FOREIGN KEY (seller_tenant_id) REFERENCES public.tenants(id);


--
-- Name: marketplace_orders fk_rails_8d7e8d8906; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_orders
    ADD CONSTRAINT fk_rails_8d7e8d8906 FOREIGN KEY (seller_tenant_id) REFERENCES public.tenants(id);


--
-- Name: access_grants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.access_grants ENABLE ROW LEVEL SECURITY;

--
-- Name: domain_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.domain_events ENABLE ROW LEVEL SECURITY;

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
-- Name: marketplace_orders; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_orders ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_orders mkt_platform_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY mkt_platform_all ON public.marketplace_orders USING ((public.app_scope() = 'mkt_platform'::text));


--
-- Name: seller_profiles mkt_platform_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY mkt_platform_all ON public.seller_profiles USING ((public.app_scope() = 'mkt_platform'::text));


--
-- Name: pagarme_recipients mkt_platform_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY mkt_platform_read ON public.pagarme_recipients FOR SELECT USING ((public.app_scope() = 'mkt_platform'::text));


--
-- Name: seller_profiles mkt_public_published; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY mkt_public_published ON public.seller_profiles FOR SELECT USING (((public.app_scope() = 'mkt_public'::text) AND ((listing_status)::text = 'published'::text)));


--
-- Name: marketplace_orders mkt_seller_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY mkt_seller_own ON public.marketplace_orders USING (((public.app_scope() = 'mkt_seller'::text) AND (seller_tenant_id = public.app_tenant_id())));


--
-- Name: seller_profiles mkt_seller_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY mkt_seller_own ON public.seller_profiles USING (((public.app_scope() = 'mkt_seller'::text) AND (seller_tenant_id = public.app_tenant_id())));


--
-- Name: pagarme_recipients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pagarme_recipients ENABLE ROW LEVEL SECURITY;

--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: probes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.probes ENABLE ROW LEVEL SECURITY;

--
-- Name: products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

--
-- Name: seller_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.seller_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_balances; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_balances ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_movements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

--
-- Name: domain_events svc_outbox_mark; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY svc_outbox_mark ON public.domain_events FOR UPDATE USING ((public.app_scope() = 'svc_outbox'::text));


--
-- Name: domain_events svc_outbox_prune; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY svc_outbox_prune ON public.domain_events FOR DELETE USING ((public.app_scope() = 'svc_outbox'::text));


--
-- Name: domain_events svc_outbox_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY svc_outbox_read ON public.domain_events FOR SELECT USING ((public.app_scope() = 'svc_outbox'::text));


--
-- Name: sync_receipts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sync_receipts ENABLE ROW LEVEL SECURITY;

--
-- Name: tenant_feature_overrides; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenant_feature_overrides ENABLE ROW LEVEL SECURITY;

--
-- Name: tenant_fiscal_parameters; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenant_fiscal_parameters ENABLE ROW LEVEL SECURITY;

--
-- Name: domain_events tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.domain_events USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: pagarme_recipients tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.pagarme_recipients USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: payments tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.payments USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: probes tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.probes USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: products tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.products USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: stock_balances tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.stock_balances USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: stock_movements tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.stock_movements USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: sync_receipts tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.sync_receipts USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: tenant_feature_overrides tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.tenant_feature_overrides USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- Name: tenant_fiscal_parameters tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_isolation ON public.tenant_fiscal_parameters USING (((public.app_scope() = 'tenant'::text) AND (tenant_id = public.app_tenant_id())));


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260709222357'),
('20260709221657'),
('20260709220310'),
('20260709201416'),
('20260709200211'),
('20260709200210'),
('20260709200209'),
('20260709195444'),
('20260709194655'),
('20260709193004'),
('20260709190841'),
('20260709180159'),
('20260709175653'),
('20260709140516'),
('20260709140515'),
('20260709140514');

