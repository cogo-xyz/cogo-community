## Edge Embedding Runbook (DeepInfra / OpenAI-compatible)

Purpose: Standardize embeddings flow so teams do not diverge. Indexing Agent triggers jobs; Edge Function streams, persists vectors, and reports events.

### Ownership & Responsibilities
- Indexing Agent: decides WHAT to embed, chunks content, and triggers Edge via SSE (`/functions/v1/embed`).
- Edge Function (`supabase/functions/embed/index.ts`):
  - Validates request, emits SSE frames (`ready`, `embed.status`, `embed.done`, `error`).
  - Calls provider using OpenAI-compatible API.
  - Upserts `vector_documents` and (optionally) `code_vectors` with dense vectors.
  - Records `bus_events` (`embed_done`, and upsert result events in mock mode).

No other service should call providers directly for embeddings. Long-running provider calls happen inside Edge.

### Provider Configuration (Single Source of Truth)
- Use ONLY these envs for embeddings:
  - `EMBEDDING_API_BASE` (e.g., `https://api.deepinfra.com/v1/openai`)
  - `EMBEDDING_MODEL_DEFAULT` (e.g., `BAAI/bge-m3`)
  - `EMBEDDING_API_KEY` (DeepInfra token)
- Do NOT use `HUGGINGFACE_API_TOKEN` or any provider-specific token envs. They are deprecated for embeddings in this project.
- The Edge code auto-adds `encoding_format: "float"` when `EMBEDDING_API_BASE` matches DeepInfra OpenAI-compatible base.
- Guard: If `EMBEDDING_API_BASE` contains `deepinfra.com` but does not end with `/v1/openai`, Edge returns `error` with code `config_error` before contacting provider.

### SSE Contract (Edge)
- Request body:
  - `session_id: string`
  - `items: Array<{ id: string; text: string }>`
  - `model?: string` (optional, defaults to `EMBEDDING_MODEL_DEFAULT`)
  - `job_id?: string` (optional; becomes `idempotency_key` if present)
- SSE events:
  - `ready` (acceptance; includes `trace_id` and optional `job_id`)
  - `embed.status` (progress: processed, total, trace_id)
  - `embed.done` (final; includes `job_id`, counts, trace)
  - `error` (provider/validation/config issues)
- Idempotency: header `Idempotency-Key` or body `job_id`. Configurable by `REQUIRE_IDEMPOTENCY`.
- Rate limits: per-session limits enforced at Edge (`EMBED_RATE_LIMIT_PER_MIN`).

### Schema & Persistence
- `vector_documents` fields used: `title`, `content`, `content_vector (vector(1024))`, `session_id`, `idempotency_key`, `trace_id`, `request_id`, `metadata`.
- `code_vectors` (optional): `file_path`, `content`, `embedding`, `session_id`, `idempotency_key`, `metadata`.
- Unique indexes on `(session_id, idempotency_key)` are recommended. Edge falls back to plain insert if the uniqueness index is not present.
- Vector dimension: 1024. RPC `get_vector_dim()` returns configured dim; mismatches are logged.

### Security & Auth
- Edge rejects unauthenticated requests unless `EDGE_AUTH_OPTIONAL=true`.
- For CI or server-to-server: use `Authorization: Bearer <SERVICE_ROLE_KEY>`.
- For client smoke: `Authorization: Bearer <ANON_KEY>` is allowed when optional auth is enabled.

### Secrets Checklist (DeepInfra)
1) `EMBEDDING_API_BASE=https://api.deepinfra.com/v1/openai`
2) `EMBEDDING_MODEL_DEFAULT=BAAI/bge-m3`
3) `EMBEDDING_API_KEY=<DeepInfra token>`
4) DO NOT set `HUGGINGFACE_API_TOKEN`; it is intentionally unsupported.

### Reference cURL (DeepInfra)
```
curl "https://api.deepinfra.com/v1/openai/embeddings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EMBEDDING_API_KEY" \
  -d '{
    "input": "The food was delicious and the waiter...",
    "model": "BAAI/bge-m3",
    "encoding_format": "float"
  }'
```

### Smoke Commands
Embed SSE:
```
curl -sN -X POST "$SUPABASE_EDGE/embed" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -d '{
    "session_id":"sess-di",
    "items":[{"id":"doc:di1","text":"DeepInfra embedding live."}],
    "job_id":"j-di1"
  }'
```

Verify DB upsert (service role):
```
curl -sS -i "$SUPABASE_URL/rest/v1/vector_documents?select=session_id,title,idempotency_key,created_at&session_id=eq.sess-di" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

### Troubleshooting
- `401/403` from provider: validate token is active and `EMBEDDING_API_BASE` ends with `/v1/openai`.
- `400 invalid model ID`: ensure `EMBEDDING_MODEL_DEFAULT=BAAI/bge-m3`.
- Empty vectors: ensure provider returns `data[].embedding` (OpenAI-compatible response). Edge maps to `content_vector`.
- No rows in `vector_documents`: check Edge logs and `error` SSE frames; ensure table exists and service role keys are configured.

### Production-only Tasks (to enable at final deployment)
- Strict authentication:
  - Disable `EDGE_AUTH_OPTIONAL` and enforce Bearer token validation against `SUPABASE_ANON_KEY` or `SUPABASE_SERVICE_ROLE_KEY`.
  - Set `verify_jwt = true` in function `config.toml` once RT/RLS policies are verified end-to-end.
- HMAC request signing:
  - Require `X-Signature` with HMAC-SHA256 over the raw body using server-side secret.
  - Validate timestamp drift via `X-Timestamp` to prevent replay.
  - Reject requests with invalid or expired signatures before doing any provider calls.
  - Rotate HMAC secret via Supabase Secrets; never commit secrets.

### Change Log (Policy)
- 2025-08-22: Removed Hugging Face-specific paths. Embeddings now standardized on OpenAI-compatible endpoint only; configured via `EMBEDDING_API_*`.
- 2025-08-22: Added DeepInfra base URL guard; docs include reference cURL.


