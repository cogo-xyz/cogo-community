## Chat Reference (Gateway Contract)

### Overview
- Default entrypoint: `/functions/v1/chat-gateway`
- Accepts either raw payload or `{ payload: {...} }` wrapper.
- Forwards to `/functions/v1/chat` and streams SSE if `Accept: text/event-stream`.
- Headers forwarded: `Authorization`, `Idempotency-Key`, `Accept`, optional `X-Timestamp`, `X-Signature`.

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

### Healthcheck
```bash
curl -sS "$SUPABASE_URL/functions/v1/chat/healthz" | jq .
```

### Notes
- Orchestrator handoff emits `chat.queued|started|handoff|done` with prompt metadata.
- RAG can include recent `public.cogo_documents` as contexts when enabled.
