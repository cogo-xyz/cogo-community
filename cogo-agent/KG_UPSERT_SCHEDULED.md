## KG Upsert via Scheduled Function (5-minute cron) — Plan

Decision: Defer implementation. This document records the agreed approach to run Neo4j upserts in batches every 5 minutes using a Supabase Scheduled Function, avoiding continuous polling load on Supabase.

### Goals
- Keep the Knowledge Graph (Neo4j) in sync with JSON artifacts by consuming `json.ingest_request` events stored in `cogo.bus_events`.
- Run as a short, periodic batch job (every 5 minutes) instead of a long-running poller.
- Preserve idempotency and reliability; safe to retry.

### Execution Modes
- Recommended (production): Delegate upsert work to an internal Node worker (HTTP endpoint) that uses Neo4j Bolt.
  - Flow: Scheduled Function → `kg-upsert-batch` (Edge) → internal worker `/upsert` → worker performs MERGE via Bolt.
  - Pros: Follows Bolt-preferred policy, better performance, flexible retries/backoff outside Edge.
- Alternative (dev only): Edge calls Neo4j HTTP endpoint directly.
  - Flow: Scheduled Function → `kg-upsert-batch` → Neo4j HTTP (`CREATEGO_NEO4J_HTTP_URL`).
  - Pros: Simpler to stand up; Cons: Not ideal for production scale.

### Batch Contract (to implement later)
- Function: `kg-upsert-batch` (Supabase Edge)
- Inputs (defaults):
  - `batch_limit`: 100
  - `timebox_ms`: 25000 (stop early if exceeded)
- Selection:
  - Source: `cogo.bus_events` where `event_type = 'json.ingest_request'` and not processed yet.
  - Order: `created_at ASC`, then `id ASC` for stability.
- Checkpointing:
  - Table: `cogo.kg_job_state` with a single-row checkpoint (e.g., `last_event_created_at`, `last_event_id`).
  - Use checkpoint to continue where last run ended; tolerate duplicates.
- Idempotency:
  - Worker performs Neo4j `MERGE` operations only.
  - Mark processed by advancing checkpoint (no per-row mutation required).

### Environment Variables
- Supabase: `SUPABASE_URL`, `SERVICE_ROLE_KEY`
- Neo4j (preferred Bolt via worker): `CREATEGO_NEO4J_URI`, `CREATEGO_NEO4J_USER`, `CREATEGO_NEO4J_PASSWORD`, `CREATEGO_NEO4J_DB`
- Neo4j (fallback HTTP): `CREATEGO_NEO4J_HTTP_URL`

### Security
- Execute batch with service role key; do not expose in client contexts.
- Internal worker endpoint must be private (container network / allowlist) and require a shared secret or signed HMAC.

### Observability
- Emit `kg.upsert.run` at start and `kg.upsert.done` at end into `cogo.bus_events` with fields:
  - `processed_count`, `duration_ms`, `failed_count`, `batch_limit`.
- Optional: store last success timestamp in `cogo.kg_job_state`.

### Scheduling
- Supabase Scheduled Function: cron expression `*/5 * * * *` (every 5 minutes) calling `kg-upsert-batch`.
- Keep per-run duration under ~30s.

### Rollout Steps (Later)
1) Add Edge function `kg-upsert-batch` (skeleton: select window → delegate/HTTP → checkpoint advance).
2) Add `cogo.kg_job_state` DDL and minimal grants.
3) Register Scheduled Function with 5-minute cron.
4) Dry-run in dev with small `batch_limit` (e.g., 20); verify events and Neo4j state.
5) Tune `batch_limit` and add backoff on worker errors; document SLOs.

This is a planning document only; no runtime changes are introduced by this commit.


