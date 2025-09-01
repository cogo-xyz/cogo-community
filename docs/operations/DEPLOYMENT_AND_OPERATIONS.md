# Deployment and Operations

This document describes how to deploy and operate the distributed setup using Supabase (Edge Functions, DB/Realtime/Storage) and the Collab API.

## Prerequisites
- Supabase CLI installed
- Project reference: `cjvgmyotqxfpxpvmwxfv`
- Environment variables
  - For EF deploy (CLI only): `SUPABASE_ACCESS_TOKEN`
  - For EF runtime calls: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
  - For server-side DB access: `SUPABASE_SERVICE_ROLE_KEY` (never ship to clients)

## Collab API (dev)
- Run: `npm run dev:collab`
- JWT protection
  - Dev local mode: set `COLLAB_REQUIRE_JWT=1` and `COLLAB_JWT_MODE=local`, `SUPABASE_JWT_SECRET=<legacy hs256 secret>`
  - Prod: set `COLLAB_REQUIRE_JWT=1` and provide Supabase Auth user JWT via `Authorization: Bearer <jwt>`
- OpenAPI:
  - Swagger UI: `http://localhost:3100/docs`
  - Spec JSON: `http://localhost:3100/docs.json`

## Edge Functions
Functions provided:
- `metrics-overview`: status counts + latest jobs
- `jobs-recent`: filtered jobs listing
- `artifacts-list`: list artifacts for job
- `workers-active`: recent worker heartbeats
- `sign-artifact`: signed URL generation for storage
- `leases-release`: release expired leases back to queue
- `dlq-list`: list dead-letter items
- `dlq-retry`: retry a dead-letter item by re-enqueuing

### Deploy (dev)
Use relaxed JWT for faster iteration.

```bash
export SUPABASE_ACCESS_TOKEN='<PAT>'
export SUPABASE_PROJECT_ID='cjvgmyotqxfpxpvmwxfv'
export SUPABASE_URL='https://cjvgmyotqxfpxpvmwxfv.supabase.co'
export SUPABASE_ANON_KEY='<ANON>'
EF_NO_VERIFY_JWT=1 bash scripts/deploy-edge.sh
```

### Deploy (prod)
Enable JWT verification by default.

```bash
export SUPABASE_ACCESS_TOKEN='<PAT>'
export SUPABASE_PROJECT_ID='cjvgmyotqxfpxpvmwxfv'
export SUPABASE_URL='https://cjvgmyotqxfpxpvmwxfv.supabase.co'
export SUPABASE_ANON_KEY='<ANON>'
unset EF_NO_VERIFY_JWT
bash scripts/deploy-edge.sh
```

### Test
```bash
export SUPABASE_URL='https://cjvgmyotqxfpxpvmwxfv.supabase.co'
export SUPABASE_ANON_KEY='<ANON>'
bash scripts/test-edge.sh

# Release expired leases
curl -s -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/functions/v1/leases-release"

# DLQ list / retry
curl -s -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/functions/v1/dlq-list?limit=20"
curl -s -X POST -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H 'Content-Type: application/json' -d '{"dlqId":1}' \
  "$SUPABASE_URL/functions/v1/dlq-retry"
```

## Realtime + EF Ops Demo (dev)
Run combined Realtime subscription and EF polling:
```bash
SUPABASE_URL=... SUPABASE_ANON_KEY=... npx ts-node src/dev/ops-dashboard-demo.ts
```

## Notes
- Service Role Key is server-side only
- Prefer EF for all public reads; keep Collab API focused on writes/mutations
- Before production, switch EF to verify JWT and keep Collab API with `COLLAB_REQUIRE_JWT=1`


