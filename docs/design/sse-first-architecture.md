## SSE-first Architecture for Chat and Embedding (Edge Functions)

### Overview
This document describes a Server-Sent Events (SSE) first architecture where Supabase Edge Functions handle both LLM inference (chat) and embedding generation. Clients connect via SSE to receive low-latency streaming deltas and progress updates without maintaining WebSocket infrastructure on the client path.

Key goals:
- Low-latency streaming over HTTP (SSE)
- Minimal cold start impact by limiting calls and using streaming early
- Strong observability: every request carries a `trace_id`
- Security: writes only from server-side (Edge), clients are read-only on DB

### Endpoints (Supabase Edge Functions)
- POST `/functions/v1/chat` (SSE): Stream model deltas for chat completion
- POST `/functions/v1/embed` (SSE): Stream embedding job progress and finalization

Notes:
- Both endpoints support CORS and expect authenticated requests. Session validation occurs in Edge.
- Both endpoints return `text/event-stream` with `Cache-Control: no-cache` and `Connection: keep-alive`.

### Chat SSE Contract
Request JSON (body):
```json
{
  "session_id": "string",
  "request_id": "string (optional)",
  "content": "user input content",
  "model": "optional model hint",
  "idempotency_key": "optional idempotency key"
}
```

SSE Events:
- `ready`: Edge accepted request and is ready to stream
- `chat.delta`: incremental model tokens
- `chat.done`: completion metadata
- `error`: unrecoverable error

Example SSE frames:
```
event: ready
data: {}

event: chat.delta
data: {"request_id":"...","seq":1,"delta":"Hello"}

event: chat.delta
data: {"request_id":"...","seq":2,"delta":" world"}

event: chat.done
data: {"request_id":"...","message_id":"...","usage":{"prompt_tokens":12,"completion_tokens":34},"trace_id":"...","total_ms":1234}
```

Error frame:
```
event: error
data: {"code":"bad_request","message":"Missing content"}
```

### Embedding SSE Contract
Request JSON (body):
```json
{
  "session_id": "string",
  "items": [
    {"id":"doc:1","text":"..."},
    {"id":"doc:2","text":"..."}
  ],
  "model": "optional model hint",
  "job_id": "optional job id"
}
```

SSE Events:
- `ready`: job accepted
- `embed.status`: progress updates (processed count)
- `embed.done`: completion metadata (counts, duration)
- `error`: unrecoverable error

### Authentication & Authorization
- Clients authenticate with a session token (Edge validates). Edge-only write access to DB (messages, embeddings). Clients can read scoped resources per RLS.
- Use short-lived session-scoped tokens where possible. Do not expose Service Role keys to clients.

### Observability & Tracing
- Every request creates/propagates a `trace_id` (UUID). All SSE frames include `trace_id`.
- Emit structured logs/metrics with `trace_id`, `request_id`, `session_id`, status codes, and latency buckets.
- Optional: forward pipeline metrics to an internal metrics collector to support `/api/metrics/trace/{traceId}` queries.

### Idempotency & Ordering
- `request_id` + optional `idempotency_key` form the dedup key.
- Deltas must carry `seq` to allow the client to reassemble in order. The server ensures strictly increasing `seq`.

### Rate Limits & Timeouts
- Per-session rate limiting on `POST /chat` and `POST /embed`.
- Apply request size limits (e.g., max content length) and token limits for model calls.
- Stream as early as possible to minimize TTFB.

### Error Handling Policy
- Invalid request → immediate `error` frame then close.
- Provider/network errors → `error` frame with `code`, close stream. Clients may retry with backoff.
- Server cancels on client disconnect (respect `AbortSignal`).

### Data Flow (High-level)
1) Client POSTs to Edge (`/chat` or `/embed`)
2) Edge validates session, generates `trace_id`, starts streaming
3) Edge calls provider (LLM/embedding), transforms into SSE events
4) Edge persists results (server-side only) and emits `chat.done`/`embed.done`
5) Client receives a continuous stream until completion/close

### Client Integration (Pseudo-code)
```ts
const res = await fetch("/functions/v1/chat", {
  method: "POST",
  headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
  body: JSON.stringify({ session_id, content, request_id })
});

const reader = res.body!.getReader();
// parse text/event-stream frames and handle events: ready, chat.delta, chat.done, error
```

### Security & Secrets
- Store provider keys in Supabase secrets or a central key manager. Never embed in code or expose to clients.
- All DB writes must be performed by Edge; clients cannot write messages or embeddings directly.

### Rollout Notes
- Keep WebSocket paths optional for internal agent communications. Client path uses SSE as the default.
- Ensure monitoring dashboards include stream open/close counts, TTFB, duration, token usage, and error rates by `trace_id`.


