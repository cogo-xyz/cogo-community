## intent-resolve – Registry/TTL/Metrics

### Purpose
- Normalize `intent.text` into `intent.keywords` via registry lookup; suggest close matches for unknown tokens.

### Endpoint
- POST `/intent-resolve` → `{ ok, trace_id, intent: { keywords[], unknown[], suggestions, language }, registry_version }`
- GET `/intent-resolve/healthz` → `{ ok }` (204/200)
- GET `/intent-resolve/info` → `{ ok, registry_version, registry_keywords_count, registry_ttl_sec, metrics_enabled }`

### Config
- `INTENT_REGISTRY_TTL_SEC` (default 60): in-memory cache TTL for registry keywords
- `INTENT_METRICS_ENABLE` (default true): emit bus events

### Suggestions
- Unknown tokens receive up to top-3 candidates via substring, Levenshtein, and trigram similarity (simple thresholds).

### Metrics (bus_events)
- `intent_resolve_succeeded` payload: `{ text_length, language, keywords_count, unknown_count, suggestions_count, latency_ms, registry_version }`
- `intent_resolve_failed` payload: `{ error, latency_ms }`

### Notes
- Admin client is used to fetch `cogo.intent_keyword` (service key required)
- TTL cache reduces DB reads; invalidate by TTL expiry or function redeploy
