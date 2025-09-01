## Figma Plugin Integration

Date: 2025-08-25

### Endpoints
- POST `/functions/v1/figma-compat/uui/symbols/map`
- POST `/functions/v1/figma-compat/uui/variables/derive`  ← Large payloads return 413; use ingest flow
- POST `/functions/v1/figma-compat/uui/generate`
- POST `/functions/v1/figma-compat/uui/ingest` (enqueue large JSON ingest)
- GET  `/functions/v1/figma-compat/uui/ingest/result?trace_id=...` (poll ingest result)
- GET  `/functions/v1/trace-status?trace_id=...` (optional polling fallback)
- (Chat) `/functions/v1/chat-gateway` (SSE proxy)
- (Context) `/functions/v1/figma-context/stream` (if applicable)

### Auth
- Development
  - Headers: `Authorization: Bearer <ANON_KEY>`, `apikey: <ANON_KEY>`
  - `projectId` MUST be a UUID. Non-UUID values are rejected.
- Production
  - Use short‑lived JWT issued by backend; do not embed raw keys in the plugin.
  - Optional HMAC enforcement per policy (disable for local dev as needed).

### SSE
- Plugin streams chat/context via EventSource
- UI relays frames (meta, delta, done) to user

### Payloads
- `cogo_ui_json` is the primary UI JSON.
- `uui_json` may be included/returned for scaffolds.
- Body size guard: for direct JSON bodies beyond the limit, server responds `413 Payload Too Large` with guidance to use the ingest flow.

### Attachments & Ingest Flow (for large JSON)
1. Client uploads JSON to Supabase Storage (signed URL flow outside of this scope), or posts metadata directly if already hosted.
2. Call `POST /figma-compat/uui/ingest` to enqueue processing. Response includes `{ ok, trace_id }`.
3. Poll `GET /figma-compat/uui/ingest/result?trace_id=...` for completion.
4. Workers record events to `cogo.bus_events` and `public.bus_events`. A Realtime broadcast is sent to `trace:{traceId}` channels.

### Installation
- Build plugin → Import manifest.json in Figma

### Trace, Realtime & Diagnostics
- Every request returns a `trace_id` for correlation.
- Realtime broadcasts: `trace:{traceId}` (if client subscribes via Supabase Realtime).
- Polling fallback: `GET /trace-status?trace_id=...` provides last known status.
- Diagnostics checklist:
  - Verify `Authorization`/`apikey` headers are present and valid.
  - Ensure `projectId` is a proper UUID.
  - For 413 errors, switch to the ingest flow.
  - Inspect network responses for `{ ok, trace_id, error }` envelopes.

### Local Verification Script
- Use the repository script to validate endpoints with your environment:
  - File: `tools/figma-verify.mjs`
  - Env required: `SUPABASE_EDGE` or `SUPABASE_PROJECT_ID`, and `SUPABASE_ANON_KEY`
  - Run: `node tools/figma-verify.mjs`
  - Expected: HTTP 200 with `{ ok: true, trace_id }` for both `symbols.map` and `uui.generate`
