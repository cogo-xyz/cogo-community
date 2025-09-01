## Release Checklist — Edge Chat & Embedding (Supabase + DeepInfra)

This checklist ensures consistent, error-free deployments for chat/embedding Edge Functions.

### 1) Ports & Endpoints (Local)
- API (agent core): 3001 -> container 3000
- Metrics: 3100
- MCP Figma: 3007 -> container 3000 (do NOT use 3002)
- MCP Browser: 3003 -> container 3000
- Edge Functions (remote): `/functions/v1/chat`, `/chat-gateway`, `/chatting`(legacy), `/embed`

### 2) Deploy Edge Functions
- Ensure `verify_jwt = false` for dev: chat, embed, chat-gateway, chatting
- Deploy:
```
supabase functions deploy chat
supabase functions deploy embed
supabase functions deploy chat-gateway
supabase functions deploy chatting
```

### 3) Secrets (Single Source of Truth)
- Core DB admin: `SERVICE_ROLE_KEY`
- Chat (if required): `CHAT_API_BASE`, `CHAT_API_KEY`, `CHAT_MODEL_DEFAULT`
- Embedding (DeepInfra):
  - `EMBEDDING_API_BASE=https://api.deepinfra.com/v1/openai`
  - `EMBEDDING_MODEL_DEFAULT=BAAI/bge-m3`
  - `EMBEDDING_API_KEY=<DeepInfra token>`
- Deprecated: `HUGGINGFACE_API_TOKEN` (DO NOT set)
- Optional dev toggles: `EDGE_AUTH_OPTIONAL=true`, `EMBED_FORCE_MOCK=true`

### 4) Provider Guard (DeepInfra)
- Edge blocks misconfigurations: if `EMBEDDING_API_BASE` contains `deepinfra.com` but not ending with `/v1/openai`, the function returns:
```
error: { code: "config_error", message: "EMBEDDING_API_BASE for DeepInfra must be https://api.deepinfra.com/v1/openai" }
```

### 5) Verification (SSE)
- Chat + Gateway:
```
SUPABASE_EDGE=$SUPABASE_EDGE SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
npm run -s chat:verify:edge
```
- Chatting (legacy proxy):
```
SUPABASE_EDGE=$SUPABASE_EDGE SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
npm run -s chatting:verify:edge
```
- Embed (DeepInfra):
```
SUPABASE_EDGE=$SUPABASE_EDGE SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
npm run -s embed:verify:edge
```
- DeepInfra direct cURL (reference):
```
curl "https://api.deepinfra.com/v1/openai/embeddings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EMBEDDING_API_KEY" \
  -d '{"input":"The food was delicious...","model":"BAAI/bge-m3","encoding_format":"float"}'
```

### 6) Rate Limits & Metrics
- Spikes:
```
SUPABASE_EDGE=$SUPABASE_EDGE SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY SPIKE_N=60 \
npm run -s chat:spike:ratelimit

SUPABASE_EDGE=$SUPABASE_EDGE SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY SPIKE_N=400 \
npm run -s embed:spike:ratelimit
```
- Aggregation (local metrics server 3100):
```
curl -s "http://localhost:3100/api/metrics/rate-limits?since_min=10" | jq .
```

### 7) Troubleshooting
- Chat SSE fails: check `CHAT_API_*` keys and Edge auth (`EDGE_AUTH_OPTIONAL`).
- Embed 401/403: validate DeepInfra token; ensure base ends with `/v1/openai`.
- No vectors inserted: check `SERVICE_ROLE_KEY` secret and table schemas.
- Use mock for isolation: `supabase secrets set EMBED_FORCE_MOCK=true` → redeploy → verify, then unset for real calls.

### 8) Production Hardening (enable at final release)
- Strict auth: disable `EDGE_AUTH_OPTIONAL`, set function `verify_jwt=true`.
- HMAC signing: require `X-Timestamp`/`X-Signature`, verify skew and signature.
- Expose only necessary endpoints; keep internal metrics private.

### 9) Rollback
- Restore previous function deploy via Supabase dashboard
- Reapply last-known-good secrets
- Re-run Verification (SSE) and Metrics checks
