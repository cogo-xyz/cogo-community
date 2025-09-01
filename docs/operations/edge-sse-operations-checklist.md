## Edge SSE Operations Checklist

### Env & Secrets
- SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY set
- CHAT_API_KEY, EMBEDDING_API_KEY configured
- Optional limits: CHAT_MAX_CONTENT_LEN, EMBED_MAX_ITEMS, CHAT_RATE_LIMIT_PER_MIN, EMBED_RATE_LIMIT_PER_MIN

### Functions
- /functions/v1/chat: streams ready/chat.delta/chat.done/error; persists messages; records bus_events
- /functions/v1/embed: streams ready/embed.status/embed.done/error; upserts vectors; records bus_events
- CORS preflight (OPTIONS) returns 204 with headers

### Database
- Tables: messages, vector_documents, code_vectors present
- Vector dims: 1024 for pgvector columns
- RLS: clients read-only by session_id; Edge writes (service role)
- Idempotency: unique indexes on (session_id, idempotency_key)[, title|file_path]

### Workers
- IndexingJobWorker triggers Edge embed job; stores sparse/meta only

### Observability
- Metrics server exposes GET /api/metrics/trace/{traceId}
- bus_events captures chat_* and embed_* events
- Scripts:
  - npm run -s chat:smoke:sse
  - npm run -s chat:smoke:trace

### Rollout
- Canary with USE_EDGE_CHAT=true for selected services
- Monitor error rates, TTFB, stream durations, rate-limit hits
- Backout: toggle USE_EDGE_CHAT=false and revert to legacy path


