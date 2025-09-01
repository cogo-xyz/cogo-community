# Collab API Flow Guide

This guide summarizes the end-to-end flow for the queue-based collaboration API, from assignment to claim, result, DLQ, and observability. It complements the OpenAPI spec in `docs/openapi/collab.yaml` and the API-only checklist in `docs/VERIFICATION_CHECKLIST_API.md`.

## 1) Security & Auth
- Prefer JWT (local dev): `COLLAB_REQUIRE_JWT=1`, `COLLAB_JWT_MODE=local`, `SUPABASE_JWT_SECRET` (HS256)
- Header: `Authorization: Bearer <JWT>`
- If JWT disabled, optional `x-api-key` can be used (configured via `COLLAB_API_KEY`)

## 2) Core entities
- jobs: queued → assigned/running → succeeded/failed (+ retry/backoff)
- job_events: committed event log (ordered by `created_at`)
- artifacts: metadata of files produced by jobs (storage path can be signed)
- worker_heartbeats_v2: presence mirror via REST heartbeat

## 3) Flow: Assign → Claim → Result
- Assign (enqueue):
  - POST `/api/collab/task.assign`
  - Body: `{ type, executorId, payload?, idempotencyKey? }`
  - Returns: `{ jobId, queued }`
- Claim (lease-based):
  - POST `/api/collab/task.claim`
  - Body: `{ executorId, workerId, leaseSeconds, typePrefix? }`
  - RPC: `claim_one_job_v3`
  - Returns: `{ job }` (or null if no available)
- Result (success/fail):
  - POST `/api/collab/task.result`
  - Body: `{ jobId, type, ok, error?, artifact?, artifacts?[] }`
  - Behavior:
    - ok=true → `jobs.status='succeeded'`, optional `artifacts` inserted
    - ok=false → attempts++, exponential backoff
      - if attempts >= max_attempts → send to DLQ (`job_dead_letters`)

## 4) DLQ and Retry
- DLQ list: Edge Function `GET functions/v1/dlq-list?limit=...`
- Retry one: Edge Function `POST functions/v1/dlq-retry { dlqId }`
  - Creates a new job with same payload; original DLQ row marked as retried

## 5) Observability
- Health: `GET /api/collab/health`
- Metrics overview: `GET /api/collab/metrics/overview`
- Job detail: `GET /api/collab/job/:id`
- Job summary: `GET /api/collab/job/:id/summary` (job + artifacts + events)
- Job events: `GET /api/collab/events/by-job/:id`
- Artifacts by job: `GET /api/collab/artifacts/by-job/:id`
- Recent jobs: `GET /api/collab/jobs/recent?limit=...&executorId=...&cursor=<ISO>`
  - Pagination: see `docs/REALTIME_CHANNELS_AND_USAGE.md` (do not pass `cursor=null`)
- Workers:
  - Heartbeat upsert: `POST /api/collab/workers/heartbeat`
  - List active: `GET /api/collab/workers/active`

## 6) Storage and artifact signing
- Artifacts stored in Supabase Storage bucket `artifacts`
- Sign for download via EF: `GET functions/v1/sign-artifact?bucket=artifacts&path=<object_path>&expires=3600`
- For local dev uploads, prefer service role key (RLS-safe) or dedicated server process

## 7) Quick curl sequence (dev/JWT local)
- Health:
```bash
curl -s http://localhost:3100/api/collab/health
```
- Assign:
```bash
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"type":"browser.run","executorId":"verify-demo","payload":{"url":"https://supabase.com"}}' \
  http://localhost:3100/api/collab/task.assign
```
- Claim:
```bash
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"executorId":"verify-demo","workerId":"worker-01","leaseSeconds":60,"typePrefix":"browser."}' \
  http://localhost:3100/api/collab/task.claim
```
- Result (fail → retry/backoff → DLQ):
```bash
JOB_ID=<uuid>
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"jobId":"'$JOB_ID'","type":"browser.run","ok":false,"error":"simulated-fail"}' \
  http://localhost:3100/api/collab/task.result
```
- Summary / Events:
```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3100/api/collab/job/$JOB_ID/summary
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3100/api/collab/events/by-job/$JOB_ID
```

## 8) Realtime
- Transactional stream: subscribe to `job_events` table changes filtered by `job_id`
- Non-transactional broadcasts: see `docs/REALTIME_CHANNELS_AND_USAGE.md`
- Sample watcher: `npm run realtime:watch` with `JOB_ID` and optional `DURATION_MS`

## 9) OpenAPI
- Collab spec: `docs/openapi/collab.yaml`
- Dev Swagger: `GET http://localhost:3100/docs.json` and `http://localhost:3100/docs`
