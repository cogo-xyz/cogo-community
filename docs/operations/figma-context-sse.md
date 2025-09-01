## Figma Context SSE Runbook

Purpose: Operate and verify the `/functions/v1/figma-context` Edge Function for chunked Figma context extraction with DB persistence and observability.

### Endpoints
- GET `/functions/v1/figma-context/healthz` — health check
- POST `/functions/v1/figma-context/start` — create job
- POST `/functions/v1/figma-context/stream` — process ONE chunk and stream SSE
- GET `/functions/v1/figma-context/status?job_id=...` — job progress
- POST `/functions/v1/figma-context/cancel` — cancel job

All endpoints accept Bearer token and `apikey` (development: `SUPABASE_ANON_KEY`).

### Required Secrets (Edge)
- `SERVICE_ROLE_KEY` (or `SUPABASE_SERVICE_ROLE_KEY`)
- `FIGMA_API_KEY`

### Database Tables
```
public.figma_jobs(id text pk, figma_url text, total_chunks int, done_chunks int, last_cursor int, status text, created_at, updated_at)
public.figma_job_chunks(job_id text fk, chunk_idx int, cursor int, status text, started_at, finished_at, error text, pk(job_id, chunk_idx))
```

### SSE Events
- `ready`, `keepalive`
- `page.ready`
- `page.includes` (emitted once; synthetic includes provided if enabled and frames missing)
- `page.chunk` (emitted per chunk)
- `progress` (when not done)
- `done` (after last chunk)
- `debug`, `error`

### Request Parameters (stream)
- `job_id` (string, required)
- `cursor` (int, required; 0..N-1)
- `figma_url` (optional; job bootstrap fallback)
- `max_nodes_per_chunk` (int, dev/testing only)
- `dev_enable_synthetic` (bool, dev/testing only)
- `dev_total_nodes` (int, dev/testing only)

### Observability (bus_events)
- `figma_job_started`
- `figma_job_chunk_done` (payload includes `job_id`, `chunk_idx`, `total_chunks`)
- `figma_job_done`

Metrics API (local): `GET http://localhost:3100/api/metrics/figma-jobs?sinceMs=3600000`
Response includes aggregate counts and recent jobs with `chunksDone/chunksTotal`.

### Smoke/Verification Scripts
- SSE basic: `npm run -s figma:verify:sse`
- Status smoke: `npm run -s figma:status:smoke`
- Events query: `SINCE_MIN=30 npm run -s figma:events:query`
- Multi-chunk verify (dev synthetic): `npm run -s figma:verify:multi`

To use a real Figma file, export `FIGMA_URL=https://www.figma.com/file/<key>/<name>` and ensure `FIGMA_API_KEY` is set in Edge secrets.

### Troubleshooting
- 401 Unauthorized: Ensure Bearer/apikey headers and Edge `verify_jwt=false` (dev only)
- `relation "public.figma_jobs" does not exist`: run migration `20250822_figma_jobs.sql`
- Chunks always 0: set `FIGMA_API_KEY` and verify the file key; for testing, enable synthetic mode
- Includes missing: ensure frame names include semantic tokens like `[HEADER]`, `[FOOTER]`, or use synthetic includes in dev

### Production Notes
- Keep JWT verify enabled; restrict `dev_*` params via schema/guards
- Route results to downstream workers (persistence/ingest) via bus_events or RLS-safe RPCs

