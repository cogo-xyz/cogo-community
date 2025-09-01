# Edge Graph – Env-only Migration Runbook

Updated: 2025-08-23

## Summary
- Edge function `graph` now uses only environment variables (no DB reads).
- Removed runtime dependency on `secure_keys` and key-vault for Neo4j.
- Distributed agents verified via Edge: ok=true, via=http_query_v2.

## What Changed
- Removed `secure_keys` lookups and Supabase DB usage from `supabase/functions/graph/index.ts`.
- Query order:
  1) `GRAPH_BRIDGE_URL` → proxy
  2) Aura HTTP Query API v2 using env: `NEO4J_HTTP_URL`, `NEO4J_USER`, `NEO4J_PASSWORD`, `NEO4J_DB` (fallback to `/tx/commit`)
  3) If not configured → `{ ok:false, stats.message: 'neo4j_not_configured' }`
- `src/routes/llmRoutes.ts`: removed `secure_keys` fallback; keys must be provided by `KeyClient` (env/manager) or return 503.

## Required Edge Secrets
- `NEO4J_HTTP_URL=https://001b3e63.databases.neo4j.io`
- `NEO4J_USER=neo4j`
- `NEO4J_PASSWORD=<password>`
- `NEO4J_DB=neo4j`
- `GRAPH_ENV=prod`

## Validation Steps
1) Deploy
```bash
supabase functions deploy graph
```
2) Health
```bash
curl -s "$SUPABASE_EDGE/graph/healthz" -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY"
```
3) Query
```bash
curl -s -X POST "$SUPABASE_EDGE/graph/query" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"cypher":"MATCH (n) RETURN count(n) as c","params":{},"env":"prod"}'
```
- Expected: `ok:true`, `stats.via: http_query_v2` (status 202)

4) Agents (inside containers)
```bash
docker exec cogo0-agent-orchestrator-1 node /edge-query.js
```
- Expected: `{ ok: true, via: 'http_query_v2' }`

## Secure Keys Removal
- Dropped schema (executed by operator):
  - `secure_keys`, `secure_keys_audit`, `secure_keys_safe`
- Code references removed:
  - `src/routes/llmRoutes.ts` (secure_keys fallback deleted)
  - Edge `graph` function no longer uses DB.

## Impact & Next
- All keys are sourced via env/KeyClient.
- If key-vault is reintroduced later, keep it out of hot-path Edge functions (use background workers or control plane).

### Graph Error Mapping
- EdgeGraphClient returns: { ok, rows, error, code, via }
- code: numeric status (from stats.status or HTTP)
- via: one of [edge,http_tx_commit,query_v2,bridge]
- smoke: `SUPABASE_EDGE=https://cjvgmyotqxfpxpvmwxfv.functions.supabase.co SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdmdteW90cXhmcHhwdm13eGZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1OTc1MTgsImV4cCI6MjA2ODE3MzUxOH0.ewOqV1vMk9fjqWK0zd-SkUIzR8v6A54UbYvw_fKnxDY npx ts-node src/scripts/ci/neo4jEdgeOnlyRegressionSmoke.ts`
