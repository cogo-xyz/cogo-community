## Hybrid SSE → Realtime Handoff: Idempotent, Scalable, Multi-device Friendly

Goals
- Start with SSE for fast first-byte and deterministic envelope.
- Early handoff to background processing for long/variable tasks.
- Broadcast progress via Supabase Realtime without DB writes requirement.
- Preserve durability via cogo.bus_events and idempotency store.
- Enable resume/retry by Idempotency-Key and trace_id.

Key Terms
- trace_id: Unique execution id returned in meta.
- Idempotency-Key: Client-provided key to deduplicate/attach to same execution.
- Handoff: Server hints client to switch to Realtime or polling.

Server Changes
1) Capabilities (intent-resolve/info)
   - sse_events includes queued, handoff
   - task_type_details: recommended_channel, handoff_supported, sla_tier
   - dev flags: dev_queue_sim, dev_handoff_after_ms

2) SSE endpoints (e.g., design-generate)
   - Emit meta with trace_id and envelope_version
   - Optionally emit queued and/or handoff
   - Close or keep SSE minimal thereafter
   - Write durable events to cogo.bus_events when appropriate

3) Realtime Relay Worker
   - Subscribes to Postgres Changes on cogo.bus_events (INSERT)
   - Broadcasts to channel name: trace:{message_id}
   - Event mapping: event_type -> broadcast event
   - Payload: event payload plus minimal metadata
   - Backoff and health logging

4) Optional /status endpoint
   - GET /status?trace_id=... returns current state (pending|running|done|error)
   - Fallback when Realtime blocked

Client (SDK) Pattern
- Always send Idempotency-Key header and store trace_id from meta
- Use streamOrRealtime():
  - Start SSE; on queued/handoff or idle, subscribe Realtime channel trace:{trace_id}
  - On disconnect: retry SSE with same Idempotency-Key or switch to Realtime only
  - Provide cancel semantics via AbortController

Flutter SDK
- Mirror TS SDK: SSE first, then Realtime subscriber util
- Same event catalog and envelope parsing

Security & Ops
- Broadcast uses Supabase Realtime. Service key recommended server-side
- cogo.bus_events in publication supabase_realtime; REPLICA IDENTITY FULL
- Indexes: (message_id), (event_type, created_at DESC)

Tests
- Edge: design-generate emits queued/handoff when flags set
- Relay: INSERT into cogo.bus_events triggers broadcast to trace:{trace_id}
- SDK: handoff/queued triggers Realtime subscription; receives done/progress

Rollout
1) Apply SQL: enable realtime for cogo.bus_events
2) Deploy RealtimeRelay worker (PM2)
3) Verify caps and dev flags
4) Run sdk:test:handoff and edge-attachments.sh

Env
- SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
- ARTIFACTS_BUCKET, FIGMA_BUCKET
- RELAY_EVENT_FILTER (optional CSV)


