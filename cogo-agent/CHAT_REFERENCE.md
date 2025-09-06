## Chat Reference (Gateway Contract)

### Overview
- Default entrypoint: `/functions/v1/chat-gateway`
- Accepts either raw payload or `{ payload: {...} }` wrapper.
- Forwards to `/functions/v1/chat` and streams SSE if `Accept: text/event-stream`.
- Headers forwarded: `Authorization`, `Idempotency-Key`, `Accept`, optional `X-Timestamp`, `X-Signature`.
- Unified error schema: `{ ok:false, error, code, message, trace_id? }` on gateway/chat errors

### Request Shape (CLI_CHAT_GATEWAY_REQUEST)
```json
{
  "projectId": "<uuid>",
  "text": "hello",
  "messages": [{"role":"user","content":"hi"}],
  "lang": "en",
  "agentId": "cogo-agent",
  "trace_id": "optional"
}
```

### Examples
- JSON response (handoff mode):
```bash
curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"payload":{"projectId":"'$COGO_PROJECT_ID'","text":"hello"}}' \
  "$SUPABASE_URL/functions/v1/chat-gateway" | jq .
```

- SSE streaming:
```bash
curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "Accept: text/event-stream" \
  -d '{"payload":{"projectId":"'$COGO_PROJECT_ID'","text":"hello stream"}}' \
  "$SUPABASE_URL/functions/v1/chat-gateway"
```

- ETag (json-get GET/HEAD):
```bash
# HEAD → ETag
ETAG=$(curl -sS -I -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/json-get?project_id=$COGO_PROJECT_ID&path=examples/af.json" \
  | awk 'tolower($1)=="etag:"{print $2}' | tr -d '\r\n')
# GET with If-None-Match → 304 when unchanged
curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "If-None-Match: $ETAG" \
  "$SUPABASE_URL/functions/v1/json-get?project_id=$COGO_PROJECT_ID&path=examples/af.json"
```

- KG upsert schedule (dev trigger):
```bash
jq -n --arg project "$COGO_PROJECT_ID" --arg prefix "docs/cogo-agent/examples/" '{project_id:$project,prefix:$prefix,window_minutes:5,limit:10}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- \
  "$SUPABASE_URL/functions/v1/kg-upsert-schedule" | jq .
```

- Response schema
```json
{ "ok": true, "trace_id": "<uuid>", "status": "handoff" }
```

- SSE events (typical)
```text
event: meta
data: {"envelope_version":"v1","trace_id":"<uuid>","event_type":"chat.start","ts":1736123456789,"headers":{"idempotency_key":"<uuid>"}}

event: llm.delta
data: {"trace_id":"<uuid>","token":"Hello","index":0}

event: llm.done
data: {"trace_id":"<uuid>","text":"Hello world","usage":{"input":12,"output":11}}
```

- Error example (method not allowed):
```bash
curl -sS -X GET -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/chat-gateway" | jq .
# { "ok": false, "error": "method_not_allowed", "code": "method_not_allowed", "message": "Only POST allowed" }
```

### Healthcheck
```bash
curl -sS "$SUPABASE_URL/functions/v1/chat/healthz" | jq .
```

### Notes
- Orchestrator handoff emits `chat.queued|started|handoff|done` with prompt metadata.
- RAG can include recent `public.cogo_documents` as contexts when enabled.
- CORS: Functions use shared headers allowing `GET, POST, OPTIONS, HEAD` and `Authorization, apikey, idempotency-key, if-match, if-none-match`.
 - System symbols: use `#_` prefix. Allowed roots: `#_uiState`, `#_appData`, `#_params`. Runtime scratchpads like `#_results`, `#_currentResult` are engine-reserved; clients should avoid persisting them.
 - GET/HEAD (json-get): `/functions/v1/json-get` supports ETag. `HEAD` returns `ETag`; `GET` honors `If-None-Match` and returns `304 Not Modified` when it matches.
  - POST (json-get): `/functions/v1/json-get` also honors `If-None-Match` and returns `304 Not Modified` when ETag matches.
  - Listing: `/functions/v1/artifacts-list` supports `HEAD` to return list ETag and `POST` `If-None-Match` for 304.
  - JSON list: `/functions/v1/json-list` supports `HEAD` with list ETag and `POST` `If-None-Match` for 304.
  - Trace status: `/functions/v1/trace-status` supports `HEAD` with ETag and `GET` with `If-None-Match` for 304 when unchanged.
  - Debug: set `DEBUG_ETAG_IN_BODY=true` to include the ETag in response JSON for troubleshooting.

### Headers & CORS
- Methods allowed: `GET, POST, OPTIONS, HEAD`
- Headers allowed: `Authorization, apikey, Content-Type, Idempotency-Key, If-Match, If-None-Match`
- Always include `Authorization: Bearer <key>` (Anon or Service); `apikey` recommended for PostgREST and internal calls

### Preconditions & Concurrency
- In production with `EDGE_STRICT_PRECONDITIONS=true`, writes MUST include concurrency headers:
  - `If-Match`: required for updates; stale ETag/version yields `412 Precondition Failed`
  - Missing `If-Match` where required yields `428 Precondition Required`
  - Version mismatches may return `409 Conflict` depending on endpoint semantics
- `json-get` supports `HEAD` with `If-None-Match` to allow `304 Not Modified`
- See `scripts/quality/smoke_prd_preconditions.sh` for example checks

### Idempotency
- Provide `Idempotency-Key` to dedupe gateway→chat upstreams
- Edge functions forward the idempotency header to orchestrator; events include `idempotency_key`

### SSE behavior
- When `Accept: text/event-stream`, gateway returns SSE from `/chat`
- Keep-Alive: `X-Accel-Buffering: no`, `Connection: keep-alive`, `Cache-Control: no-cache`
- Event types: `meta`, `llm.delta`, `llm.done` (minimum set for reference)
