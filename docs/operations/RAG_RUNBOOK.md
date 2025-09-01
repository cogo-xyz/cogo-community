# RAG Runbook (Dev/Prod)

This runbook documents environment switches and operational flows for the RAG path (Edge + Client).

## Environment Variables

| Variable | Scope | Default | Purpose |
|---|---|---|---|
| RAG_USE_EDGE | Node client | false | Route `SupabaseVectorStore` to Edge `/functions/v1/rag/search` when true. |
| RAG_TOP_K | Node client | 10 | Default top-k if not provided by caller. |
| RAG_THRESHOLD | Node client | 0.7 | Default similarity threshold if not provided. |
| EDGE_VERIFY_JWT | Edge | false | Require JWT verification on Edge. Enable in prod. |
| EDGE_REQUIRE_HMAC | Edge | false | Require HMAC signature on request body. Enable in prod. |
| EDGE_RAG_HMAC_SECRET (or RAG_HMAC_SECRET) | Edge + Client | — | Shared secret for HMAC. Set as Function secret; client signs when present. |
| EDGE_DEV_NO_AUTH | Edge + Client | false | If true (or `NODE_ENV=development`), Edge skips JWT/HMAC checks and client skips signing. Use only in development. |
| RAG_EDGE_CACHE_MS | Edge | 60000 | TTL for in-memory cache of `/rag/search` responses. Set 0 to disable. |
| RERANK_HYBRID | Node client | false | If true, combine similarity with keyword overlap. |
| RERANK_ALPHA | Node client | 0.2 | Weight for keyword component in hybrid rerank (0..1). |
| RERANK_USE_LLM | Node client | false | Reserved toggle for optional LLM-based rerank. |
| RAG_ALERT_WEBHOOK | Metrics | — | Webhook URL to receive RAG alerts. |
| RAG_ALERT_P50_MS | Metrics | 2000 | p50 latency alert threshold in ms. |
| RAG_ALERT_P95_MS | Metrics | 5000 | p95 latency alert threshold in ms. |
| RAG_ALERT_BACKLOG | Metrics | true | If true, alert when ingest>0 and search=0. |
| RAG_CACHE_ADMIN_TOKEN | Edge | — | Optional token to authorize `/functions/v1/rag/cache/bust`. Dev is allowed without token. |

Notes:
- Edge reads `Deno.env.get('EDGE_DEV_NO_AUTH')`; set it as a Supabase Function secret (dashboard or CLI). The Node client can also read it (process.env) and will skip `X-Signature` when in dev.
- In prod, do NOT set `EDGE_DEV_NO_AUTH`.

## Dev Quickstart

1) Local Node client
```
export NODE_ENV=development
export EDGE_DEV_NO_AUTH=true
export RAG_USE_EDGE=true
# Optional: tune defaults
export RAG_TOP_K=5
export RAG_THRESHOLD=0.3
```

2) Edge Functions (Supabase)
- Set function secrets from the dashboard or CLI:
```
supabase functions secrets set EDGE_DEV_NO_AUTH=true --project-ref <projectRef>
# optional cache-bust admin
supabase functions secrets set RAG_CACHE_ADMIN_TOKEN=<token> --project-ref <projectRef>
```
- For dev, keep `EDGE_VERIFY_JWT=false`, `EDGE_REQUIRE_HMAC=false` (defaults).

## Prod Hardening

Set the following (Edge function secrets and CI/CD env):
```
EDGE_VERIFY_JWT=true
EDGE_REQUIRE_HMAC=true
EDGE_RAG_HMAC_SECRET=<random-32B-hex>
RAG_USE_EDGE=true
# Tune as needed
RAG_TOP_K=5
RAG_THRESHOLD=0.65
```
Client automatically signs body with `X-Signature` when `RAG_HMAC_SECRET` is present and not in dev mode.

## Request/Response Shape

POST `/functions/v1/rag/search`
POST `/functions/v1/rag/cache/bust`
```
Headers: { X-Admin-Token: <token> } (dev: optional)
Body: { "key": "<exact-cache-key>" } // omit to clear all
```
```
{
  "query": "...",
  "top_k": 5,
  "threshold": 0.7,
  "return_query_vector": false
}
```

Response:
```
{
  "ok": true,
  "top_k": 5,
  "items": [
    {
      "id": "...",
      "content": "...",
      "snippet": "...",        // first 240 chars
      "similarity": 0.82,
      "score": 0.82,            // alias of similarity
      "source": "vector_documents|components|...",
      "metadata": { ... }
    }
  ]
}
```

## Metrics & Gates

- RAG search executions emit `bus_events(event_type='rag_search_executed', payload.latency_ms)`.
- Dashboard pulls `/api/metrics/rag` (ingest/search counts) and shows slow/backlog alerts.
- Cache hitRate available at `/api/metrics/rag/cache`.
- CI gate: `npm run rag:gate` (defaults: `p50<2000ms`, `avgItems>=1`).

## Alerts

- POST `/api/alerts/rag` checks current metrics and sends a webhook when thresholds are violated.
- Configure env: `RAG_ALERT_WEBHOOK`, `RAG_ALERT_P50_MS`, `RAG_ALERT_P95_MS`, `RAG_ALERT_BACKLOG`.

## Troubleshooting

- Empty results in dev: ensure `RAG_USE_EDGE=true` and `SUPABASE_EDGE` points to your Functions domain.
- HMAC failures in prod: check `EDGE_RAG_HMAC_SECRET` on Edge and `RAG_HMAC_SECRET` on the client match; clock skew not relevant (HMAC is stateless).
- Vector mismatch: verify `VECTOR_DIMENSIONS` SQL RPC vs client env.


