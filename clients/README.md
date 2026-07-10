# Generated clients

Per ADR-0009, the platform's typed clients are **generated from the one contract**
(`contracts/openapi/v1.yaml`) — never hand-written, never a second API:

- **TypeScript** (`typescript-fetch`) — POS UI, portal frontends.
- **Rust** (`reqwest`) — POS sync engine.

The public API offered to third parties is the same surface, scoped by auth.

## Generate locally

```sh
npx @openapitools/openapi-generator-cli batch \
  --includes-base-dir . clients/openapitools.json
# → clients/typescript/, clients/rust/
```

`clients/openapitools.json` pins the generator version and both targets.

## CI status (S1-G3 · I2 — lightened, per the gate's pace decision)

The **contract and its compatibility gate are enforced in CI today**
(`bin/lint-openapi`, `bin/check-openapi-compat`). The full **build-both-clients-green
in CI** pipeline (Node + Rust + openapi-generator toolchains) is **deferred debt** —
it needs a Node + Rust CI stack this Ruby/Postgres pipeline doesn't yet carry. The
generator config above is the concrete, committed pipeline definition; wiring the CI
job that runs it green is the remaining I2 work.
