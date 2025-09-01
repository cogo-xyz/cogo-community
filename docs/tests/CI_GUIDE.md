## CI Optional Suites (Distributed)

This repo provides optional CI workflows to validate distributed agent paths without blocking PRs by default. Enable them via repository variables or trigger manually.

### Workflows
- Distributed Smoke (Optional): `.github/workflows/smoke-distributed.yml`
  - Verifies LLM chat routing, job enqueue/consume path, basic health and routing endpoints.
  - Trigger: workflow_dispatch or `CI_SMOKE_ENABLE='true'` repo variable.

- Monitoring API Poll (Optional): `.github/workflows/monitoring-poll.yml`
  - Boots metrics server and polls `/api/metrics/*` and `/api/search/*` endpoints.
  - Trigger: workflow_dispatch or `CI_MONITOR_POLL_ENABLE='true'`.

- Quality Light (Optional): `.github/workflows/quality-light.yml`
  - Runs a small subset of quality scenarios (`QUALITY_LIGHT_LIMIT`, default 3).
  - Trigger: workflow_dispatch or `CI_QUALITY_LIGHT_ENABLE='true'`.

- PR Lite Checks (Optional): `.github/workflows/pr-lite.yml`
  - Runs smoke → monitoring → quality-light(2) and aggregates results.
  - Exits non-zero if aggregate gate fails (smoke, monitor, quality, and thresholds).
  - Trigger: workflow_dispatch or `CI_PR_LITE_ENABLE='true'`.

### Thresholds (aggregate gate)
- Env vars for `ci:aggregate:prlite`:
  - `QUALITY_MIN_RAN` (default 1): minimum number of scenarios executed successfully.
  - `HEALTH_TTL_MIN` (default 1440): max age minutes for provider health rows.
  - `ROUTING_REQUIRE_RANKED` (default 1): minimum ranked models required.

### Local quickstart
1) Set env (example):
```
export SUPABASE_URL=https://<project-ref>.supabase.co
export SUPABASE_ANON_KEY=<anon-jwt>
export SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
export SUPABASE_SECRET_KEY=sb_secret_...
export KEY_VAULT_URL=$SUPABASE_URL/functions/v1/key-vault
export ROUTER_SELECT_URL=$SUPABASE_URL/functions/v1/router-select
export NEO4J_URI=neo4j+s://<your-instance>.databases.neo4j.io
export NEO4J_USERNAME=neo4j
export NEO4J_PASSWORD=<password>
```

2) Run smoke: `npm run ci:smoke:distributed`
3) Poll monitoring: `npm run monitor:poll`
4) Quality light: `QUALITY_LIGHT_LIMIT=2 npm run quality:run:light`
5) Aggregate: `QUALITY_MIN_RAN=2 HEALTH_TTL_MIN=1440 ROUTING_REQUIRE_RANKED=1 npm run ci:aggregate:prlite`

One-shot locally: `npm run ci:run:prlite:local`

All outputs are uploaded as artifacts in CI and saved under `reports/` locally.

Notes:
- Edge Functions often require `Authorization: Bearer $SUPABASE_ANON_KEY` and `apikey: $SUPABASE_PUBLISHABLE_KEY` per the new API keys policy.
- If the Indexing worker fails with Neo4j URL errors, ensure the Neo4j env vars are exported in the same shell.

---

## CI Environment (Record Only; apply at end of development)

In this development phase, we avoid changing GitHub Actions. Record the required variables/secrets here to prevent omissions. Apply them right before production deployment.

### Repository Variables (to set later)
- `KEY_ENV=dev`
- `KEY_BEARER=$SUPABASE_ANON_KEY`
- `SUPABASE_URL=https://<project-ref>.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY=sb_publishable_...`
- `ROUTER_SELECT_URL=$SUPABASE_URL/functions/v1/router-select`
- `KEY_VAULT_URL=$SUPABASE_URL/functions/v1/key-vault`
- `NEO4J_URI=neo4j+s://<instance>.databases.neo4j.io`
- `NEO4J_USERNAME=neo4j`
- `NEO4J_PASSWORD=*****`
- `QUALITY_LIGHT_LIMIT=4`

### Repository Secrets (to set later)
- `SUPABASE_SERVICE_ROLE_KEY=sb_secret_...`

### Supabase Key Policy (reference)
- Edge Functions: `Authorization: Bearer $SUPABASE_ANON_KEY`, `apikey: $SUPABASE_PUBLISHABLE_KEY` (fallback Secret/Anon)
- DB writes (vectors/usage/jobs): `SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_SECRET_KEY` only (do not use ANON)


### Legacy Compat (PR Lite helper)
- One-shot local compat bundle: `npm run -s ci:pr:compat`
- Runner E2E (navigate/call_flow/saveTo): `npm run -s compat:runner:e2e`
- Directory run (optional): `LEGACY_DIR=/path/to/legacy_dir npm run -s compat:run:dir`
- To include in PR Lite, invoke `ci:pr:compat` before aggregate gate.



