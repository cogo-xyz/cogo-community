## Supabase Chatting/Talking Interface & Protocol

> Deprecated: Use `/functions/v1/chat` (SSE) as the canonical endpoint and `/functions/v1/chat-gateway` as ingress. The `chatting/*` endpoints are kept as a temporary proxy and will be removed after the migration window.

### Goals
- Minimal, platform-neutral chat interface compatible with constrained clients (e.g., Figma/IDE).
- Clear separation: Chatting (ingress/API) → Talking (LLM/Tool orchestration).
- Reuse common Envelope, scoping, and tracing (see `docs/integration/Supabase-Realtime-Distributed-Protocol.md`).

### Roles
- Chatting (Edge Function): HTTP ingress for chat messages, auth/backpressure/idempotency, queueing.
- Chat Gateway Worker (Talking): Consumes queued messages, runs LLM/tool logic or delegation, emits bus/realtime events.

### Identifiers & Scope
- `project_id` (uuid, required): tenant boundary.
- `session_id` (string, optional): UI stream scope.
- `cogo_project_id` (uuid, optional): internal COGO scope; independent from `project_id`.
- `thread_id` (uuid|string, optional): logical conversation thread.
- `message_id` (uuid): assigned on enqueue.
- `trace_id` (string): end-to-end correlation added to envelopes and events.

### Message Model
```json
{
  "projectId": "<uuid>",
  "sessionId": "sess_...",
  "cogoProjectId": "<uuid>",
  "threadId": "chat:...",
  "role": "user|assistant|system",
  "content": [ { "type": "text", "text": "Hello" } ],
  "toolCalls": [ { "name": "search", "args": {"q": "..."} } ],
  "metadata": { "locale": "ko-KR" },
  "idempotencyKey": "optional-key"
}
```

### HTTP APIs (Edge)
- POST `/chatting/enqueue`
  - Body: Message model fields.
  - Effects:
    - Insert into `public.agent_messages` with `{ service: 'chat', role: 'gateway', shard: 0, project_id, payload }`.
    - Backpressure guard using `ENQUEUE_MAX_QUEUE` per project.
    - Idempotency reuse by `idempotencyKey`.
  - Response: `{ ok, id: <message_id> }`.

- GET `/chatting/talking/result?id=<message_id>`
  - Poll `public.bus_events` for `chat_call_succeeded|chat_call_failed`.
  - Response: `{ ok, status: 'ok'|'error'|'pending', event? }`.

- POST `/chatting/respond`
  - Human-in-the-loop. Insert `human_response_received` into `public.bus_events` with `{ prompt_type, payload }`.

- GET `/healthz`
  - Liveness check: `{ ok: true, ts }`.

### Realtime
- Channels
  - `plugin:<session_id>` (primary, UI scope)
  - `project:<project_id>` (project scope broadcast)
- Envelope
  - Use `ProtocolEnvelope<T>`; fields: `type`, `data`, and metadata: `trace_id`, `project_id`, `cogo_project_id`, `session_id`, `message_id`, `service`, `role`, `shard`.
  - Server option `BROADCAST_ENFORCE_META=1` enforces presence of `trace_id`, `project_id`, `cogo_project_id` (drops otherwise with warn log).

### Event Types
- Bus (`public.bus_events`): `chat_call_scheduled`, `chat_call_started`, `chat_call_succeeded`, `chat_call_failed`, `human_response_received`.
- Realtime Envelope mapping: `progress`, `input_required` (reserved), `done`, `error`.

### Backpressure & Idempotency
- Backpressure: `ENQUEUE_MAX_QUEUE` per project; optional rate-limit per IP.
- Idempotency: server reuses latest queued/processed message for the same `project_id` + `idempotencyKey`.

### Security
- No-auth mode: `Authorization: Bearer <ANON_KEY>`, server uses Service Role to write DB.
- Auth mode (future): validate Supabase Auth session and project membership (RLS aligned).

### Observability
- Metrics (server):
  - GET `/api/metrics/chat/project?projectId=...&cogoProjectId=...` → counts, p50, p95, successRate, recent.
  - GET `/api/mcp/summary/project?projectId=...` → `chat` aggregate embedded.
  - GET `/api/mcp/dashboard/project?projectId=...` → `chat` aggregate embedded.
- Timeline: `/api/mcp/timeline?messageId=...` shows unified timeline (MCP/Chat mixed if applicable).

### Compatibility
- Aligns with Envelope and scoping used by MCP/UUI; minimal client changes for IDE/Plugins.

### DoD (E2E)
1) POST `/chatting/enqueue` → `{ ok, id }`.
2) Realtime `progress/done` via `plugin:<session_id>` (also mirrored to `project:<project_id>`).
3) GET `/chatting/talking/result?id=...` → `{ ok, status: 'ok'|'error', event }`.
4) Metrics/Dashboard show `chat_*` aggregates.

### Example Client Snippets
- Enqueue (fetch)
```ts
await fetch(EDGE + '/chatting/enqueue', {
  method: 'POST',
  headers: { 'content-type': 'application/json', Authorization: 'Bearer ' + ANON, apikey: ANON },
  body: JSON.stringify({ projectId, sessionId, role: 'user', content: [{ type: 'text', text: 'hello' }] })
});
```
- Result poll
```ts
await fetch(EDGE + '/chatting/talking/result?id=' + messageId, { headers: { Authorization: 'Bearer ' + ANON, apikey: ANON } });
```
- SSE Feed
```ts
const res = await fetch(HOST + '/api/chat/feed?projectId=' + projectId + '&cogoProjectId=' + cogoProjectId, { headers: { accept: 'text/event-stream' } });
```


