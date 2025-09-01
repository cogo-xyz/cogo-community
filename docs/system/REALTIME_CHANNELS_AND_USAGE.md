## Realtime Channels and Usage (Updated 2025-08-09)

This document summarizes the realtime channels used by the distributed agents and MCP workers, and their purposes.

### Channel taxonomy
- agents:{agentId}
  - Purpose: Heartbeat, status, metrics via Presence/Broadcast
  - Broadcast types: `agent.status`, `worker.metrics`
- jobs:{jobId}
  - Purpose: Non-transactional job events stream to subscribers
  - Broadcast types: `job.claimed|started|progress|succeeded|failed`
- system:events
  - Purpose: System-wide announcements

### Control-plane vs Data-plane
- Control-plane (Realtime): small JSON, routing, status (Presence/Broadcast)
- Transactional Stream: `job_events` table change stream via Supabase Realtime (DB triggers write events)
- Data-plane (DB/Storage): artifacts, job rows, idempotency, audits

### DB mode (lease-based) overview
- Enqueue: insert into `public.jobs` with `status='queued'` and `executor_id`
- Claim: workers claim with lease (`lease_owner`, `lease_until`) or RPC `claim_one_job`
- Process: worker updates `status` to `succeeded`/`failed`, records artifacts
- Recovery: expired leases can be reset to `queued`

Example (enqueue browser)
```json
{"id":"<uuid>","type":"browser.screenshot","status":"queued","executor_id":"default","payload":{"url":"https://supabase.com"}}
```

### Keys and clients
- Publishable key (sb_publishable_*): use for all client-side realtime and DB writes guarded by RLS.
- Secret key (sb_secret_*): server-only (Edge Functions / backend). Never ship to clients/workers.

### Workers
- Browser worker
  - Listens: DB queue (`jobs` claim) + optional Realtime broadcasts
  - Reports: `task.result` API or direct DB update; broadcasts job events
  - Artifacts: Storage upload + `artifacts` row insert
- Figma/Python worker: 동일 패턴

#### Heartbeat mirror (DB)
- REST: `POST /api/collab/workers/heartbeat` → `worker_heartbeats_v2` UPSERT
- Query: `GET /api/collab/workers/active` (최근 20초)
- EF: `GET functions/v1/workers-active` (서버측 읽기)

### Error handling
- Realtime glitches: retry subscribe; fallback to DB poll if needed.
- Network-sensitive workloads (browser): increase nav timeout, use headful mode, or force-success fallback (tiny PNG) when required.

### Proven E2E flows (2025-08-08)
- Browser screenshot
  - Input: `url = https://supabase.com`
  - Result: signed URL and `artifacts` row created (example name `screenshot.png`)
- Figma export
  - File: `u9VG9NhC6C8hVJYx8o9rpS`
  - Nodes: `1:8, 1:2, 1:4`
  - Result: signed URLs and `artifacts` rows created (PNG)

### Example payloads
- task.assign (browser)
  ```json
  {"jobId":"<uuid>","type":"browser.screenshot","payload":{"url":"https://supabase.com"}}
  ```
- task.result (browser)
  ```json
  {"ok":true,"action":"screenshot","url":"https://supabase.com","artifact":{"name":"screenshot.png","size":744734,"url":"<signed-url>"},"artifactRecorded":true,"jobId":"<uuid>"}
  ```

### Transactional Consistency via DB
- Create `job_events` and write events from `jobs` triggers (INSERT/UPDATE)
- Subscribe to table changes on `job_events` for ordered, committed events


### Pagination and cursor semantics
- Jobs listing endpoints return `{ items, count, nextCursor }`.
- Do not call the next page if `nextCursor` is `null` (passing `cursor=null` will error).
- Ordering is `created_at` DESC; pass `nextCursor` as `cursor` to fetch the next page.
- Applies to:
  - Collab: `GET /api/collab/jobs/recent?limit=...&executorId=...&cursor=<ISO>`
  - Edge Functions: `GET functions/v1/jobs-recent?limit=...&cursor=<ISO>`

Example paging loop (bash):
```bash
BASE="http://localhost:3100/api/collab/jobs/recent?limit=5&executorId=verify-demo"
CUR=$(curl -sS -H "Authorization: Bearer $TOKEN" "$BASE" | jq -r '.nextCursor')
while [ "$CUR" != "null" ] && [ -n "$CUR" ]; do
  RESP=$(curl -sS -H "Authorization: Bearer $TOKEN" "$BASE&cursor=$CUR")
  echo "$RESP" | jq '.items | length'
  CUR=$(echo "$RESP" | jq -r '.nextCursor')
done
```


### Channel mapping in code (reference)
- In code, legacy channel groups are centralized in `SupabaseRealtimeQueue.CHANNELS` and the new logical channels are mapped by `SupabaseRealtimeAdapter`.
- This allows docs to use concise forms like `agents:{agentId}` and `jobs:{jobId}`, while the adapter resolves them to concrete names.

Example references:

```27:62:src/services/SupabaseRealtimeQueue.ts
  static readonly CHANNELS = {
    SYSTEM: {
      GATEWAY: 'system.gateway',
      HEALTH: 'system.health',
      CONFIG: 'system.config',
      EVENTS: 'system.events'
    },
    AGENTS: {
      ORCHESTRATOR: 'agents.orchestrator',
      EXECUTOR: 'agents.executor',
      RESEARCH: 'agents.research',
      INDEXING: 'agents.indexing',
      SANDBOX: 'agents.sandbox'
    },
    TASKS: {
      REQUESTS: 'tasks.requests',
      PROGRESS: 'tasks.progress',
      RESULTS: 'tasks.results',
      ERRORS: 'tasks.errors',
      DELEGATION: 'tasks.delegation'
    }
    // ... omitted
  }
```

```42:55:src/communication/adapters/SupabaseRealtimeAdapter.ts
  private setupChannelMappings(): void {
    this.channelMappings.set(SYSTEM_CHANNELS.HEARTBEAT, SupabaseRealtimeQueue.CHANNELS.SYSTEM.HEALTH)
    this.channelMappings.set(SYSTEM_CHANNELS.DISCOVERY, SupabaseRealtimeQueue.CHANNELS.AGENTS.ORCHESTRATOR)
    this.channelMappings.set(SYSTEM_CHANNELS.TASKS, SupabaseRealtimeQueue.CHANNELS.TASKS.REQUESTS)
    // ... omitted
  }
```

### Minimal subscription example (DB change stream)
### Storage and artifacts flow
- Data-plane: files are stored in Supabase Storage bucket `artifacts`.
- Metadata-plane: DB table `artifacts` records `job_id`, `name`, `size`, `url` (optional), `created_at`.
- Typical flow:
  1) Worker uploads object to `artifacts/<structured-path>`
  2) Worker inserts row into `public.artifacts` with `job_id` and metadata
  3) Client lists artifacts via Collab API or EF, and calls `sign-artifact` to obtain a temporary URL
- RLS considerations:
  - Use service role key for server-side upload in development
  - Clients should never receive secret keys; use EF `sign-artifact` for download links
```ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!)
const jobId = process.env.JOB_ID!

const channel = supabase.channel(`job-events-${jobId}`)
channel.on('postgres_changes', {
  event: 'INSERT',
  schema: 'public',
  table: 'job_events',
  filter: `job_id=eq.${jobId}`
}, (payload) => {
  console.log('job_event:', payload.new)
}).subscribe()
```

