# Changelog

## 1.0.0 (2026-07-10)


### Features

* **contract:** backward-compat check for the OpenAPI surface ([#37](https://github.com/t8mhq/t8m-core-next/issues/37)) ([2b8ca60](https://github.com/t8mhq/t8m-core-next/commit/2b8ca60304c4f268bcc5bedb8ba80a74bd7e48a8))
* **contract:** OpenAPI v1 skeleton — five auth scopes, header-versioned ([#36](https://github.com/t8mhq/t8m-core-next/issues/36)) ([13e5534](https://github.com/t8mhq/t8m-core-next/commit/13e55342e13eb0f979ce815440cdc65a516b39ca))
* **events:** payload schema registry + additive-only CI compat ([#31](https://github.com/t8mhq/t8m-core-next/issues/31)) ([bb1c6f3](https://github.com/t8mhq/t8m-core-next/commit/bb1c6f3e66999bf238f07402c508873cd1e36afa))
* **flags:** one flag idiom — override to plan to default + governance ([d9241fb](https://github.com/t8mhq/t8m-core-next/commit/d9241fbc2d69328308f7bbdf4b223373a9bc6881))
* **ia:** read-only satellite role — zero write paths to core ([#46](https://github.com/t8mhq/t8m-core-next/issues/46)) ([f9840c9](https://github.com/t8mhq/t8m-core-next/commit/f9840c996cc32472d8ef8a4e3e5b3cecc14a1350))
* **marketplace:** seller activation gates listing (fiscal + KYC) ([#47](https://github.com/t8mhq/t8m-core-next/issues/47)) ([016f7f1](https://github.com/t8mhq/t8m-core-next/commit/016f7f18da90e4549867997b2857827a94f33e1f))
* **marketplace:** sub-order materialization walking skeleton ([#45](https://github.com/t8mhq/t8m-core-next/issues/45)) ([4358a76](https://github.com/t8mhq/t8m-core-next/commit/4358a76c6360a555fd6df4eb1b335b918099c891))
* **outbox:** consumer idempotency ledger + reference consumer ([#30](https://github.com/t8mhq/t8m-core-next/issues/30)) ([74afd1c](https://github.com/t8mhq/t8m-core-next/commit/74afd1c575d8f6848bbc23b70030e3bb00719d0c))
* **outbox:** domain_events transactional outbox + publisher ([#29](https://github.com/t8mhq/t8m-core-next/issues/29)) ([c5be2b6](https://github.com/t8mhq/t8m-core-next/commit/c5be2b6396b6ed1376324f47d943bd83d39bb0d0))
* **outbox:** retention sweep with archival carve-out ([#32](https://github.com/t8mhq/t8m-core-next/issues/32)) ([206e493](https://github.com/t8mhq/t8m-core-next/commit/206e493dc71dcde0f7f4948ceaf06ff7742faea9))
* **packs:** eight bounded-context packs with encoded dependency graph ([a46ee21](https://github.com/t8mhq/t8m-core-next/commit/a46ee21452bb373a77f38025c5500310b2882a1e))
* **packwerk:** total boundary enforcement + todo-file ban ([81401e6](https://github.com/t8mhq/t8m-core-next/commit/81401e69d696864972193e7b9644c9503c617ea1))
* **payments:** Pagar.me recipients + KYC status ([#41](https://github.com/t8mhq/t8m-core-next/issues/41)) ([def2ba4](https://github.com/t8mhq/t8m-core-next/commit/def2ba4f5a3894ba2e5de94478d98cc21f7e8626))
* **payments:** Pagar.me webhook — signature, idempotency, enqueue-never-inline ([#43](https://github.com/t8mhq/t8m-core-next/issues/43)) ([5100154](https://github.com/t8mhq/t8m-core-next/commit/5100154729f4d827e520e81f3fe52cfa10c171c0))
* **payments:** PaymentGateway interface + Pagar.me (mock) adapter ([#40](https://github.com/t8mhq/t8m-core-next/issues/40)) ([e3b14fa](https://github.com/t8mhq/t8m-core-next/commit/e3b14fadd581df35bfdcc96ed25222153879f2ef))
* **payments:** settlement ingestion + fee capture → payment_settled ([#44](https://github.com/t8mhq/t8m-core-next/issues/44)) ([1ebfd76](https://github.com/t8mhq/t8m-core-next/commit/1ebfd7698a45095fed276a9188904049dcbd19d4))
* **payments:** split-rule construction (reconciled, recipient-gated) ([#42](https://github.com/t8mhq/t8m-core-next/issues/42)) ([a95c326](https://github.com/t8mhq/t8m-core-next/commit/a95c326ecc526c5103a2354187d7ff4b8ce0ff7d))
* **rls:** grant scope — access_grants + read-only grant policies ([#17](https://github.com/t8mhq/t8m-core-next/issues/17)) ([a645883](https://github.com/t8mhq/t8m-core-next/commit/a645883dc10f93aca381df64102be9a2667c51f4))
* **rls:** job runner guard — no tenant work without a scope ([#19](https://github.com/t8mhq/t8m-core-next/issues/19)) ([b7a629b](https://github.com/t8mhq/t8m-core-next/commit/b7a629b54e7bf432ba0a06118573c62fbdf62661))
* **rls:** marketplace scope — three contexts on placeholder tables ([#18](https://github.com/t8mhq/t8m-core-next/issues/18)) ([21a5359](https://github.com/t8mhq/t8m-core-next/commit/21a53597f2b0e437f22d745c30ff623ab3952117))
* **rls:** matrix suite + RLS schema lint as required checks ([#20](https://github.com/t8mhq/t8m-core-next/issues/20)) ([e80f3cc](https://github.com/t8mhq/t8m-core-next/commit/e80f3cca1df2eb8542bd4021d99d0c77c76efcef))
* **rls:** tenant scope — context helpers, policy template, middleware ([#16](https://github.com/t8mhq/t8m-core-next/issues/16)) ([968b7ee](https://github.com/t8mhq/t8m-core-next/commit/968b7ee6738110f71e5b2461dc196fe7f1a02397))
* **scaffold:** Rails 8 app with D5 role split and D8 money lint ([6f6c2ed](https://github.com/t8mhq/t8m-core-next/commit/6f6c2edaab85ef8c024ab12a6cc53d3d8ad76c73))
* **schema:** reservations + overlap-proof fiscal parameters ([#34](https://github.com/t8mhq/t8m-core-next/issues/34)) ([cafba7f](https://github.com/t8mhq/t8m-core-next/commit/cafba7f119f19465f6bef640bffa5e928cd37630))
* **stock:** immutable stock_movements + derived balance + reconciliation ([#35](https://github.com/t8mhq/t8m-core-next/issues/35)) ([c454ac6](https://github.com/t8mhq/t8m-core-next/commit/c454ac6c25b36999941dbe48bca2c29c8667300b))
* **sync:** POS sync boundary endpoints (stub) with idempotent replay ([#38](https://github.com/t8mhq/t8m-core-next/issues/38)) ([4ec2d97](https://github.com/t8mhq/t8m-core-next/commit/4ec2d97bf49a32a96787df8563f09c3df092aba8))
