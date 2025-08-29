# COGO Agent – Developer Manual

This guide targets developers integrating and operating the COGO Agent. It covers setup, APIs, pipelines, security, and concrete samples.

## 1. Setup & Environments

- Environment variables are centrally managed (no secrets committed).
- Services: Agent (compile/run/orchestrate), Metrics server, Edge (`figma-compat`) for ingestion/short tasks.
- Local readiness: ensure Metrics server availability before smokes/gates.

## 2. Pipelines & Artifacts

- BDD pipeline: parse → compile → run → RAG (pgvector) → KG (Neo4j) → reports/artifacts.
- Quality gates (examples): BDD coverage, RAG hit rate, KG edge counts, ActionFlow step sanity, error rate.
- Artifacts:
  - Inline previews: `artifacts.*_preview` for small JSONs
  - Links: `artifacts.links[]` with signed URLs for large payloads
  - Trace lookup: `/api-router/metrics/trace/{traceId}` aggregates events and artifacts
  - Env: `ARTIFACTS_BUCKET` (default `artifacts`), `ARTIFACTS_SIGN_TTL_SEC` (default 600)

## 3. Edge Endpoints (for ingestion/conversion)

- `/figma-compat/uui/symbols/map` – Map CreateGo/Figma → UUI & COGO JSON
- `/figma-compat/uui/variables/derive` – Variable scaffolding
- `/figma-compat/uui/bdd/generate|refine` – BDD draft/refine (short-lived)
- `/figma-compat/uui/actionflow/refine` – Flow skeleton refine (not executing)
- `/figma-compat/uui/generate|generate/llm` – Demo generation
- `/figma-compat/uui/presign` – Storage presign, `/uui/ingest` – asynchronous ingest event

Note: Edge is not for long-running tasks.

## 4. ActionFlow – Authoring & Execution

- Authoring: Confirm BDD per event, compile to ActionFlow JSON (`actionType`, `actionId`, `params`, `guards`).
- Data actions: enforce `REST_ALLOWED_HOSTS`; use timeouts/retries; map responses via `saveTo` with validated paths.
- Execution: use Agent Runner (not Edge). Timings can be enabled per-step (binding/whitelist/fetch/parse/branches).

### Sample – Minimal Flow (excerpt)
```json
{
  "id": "loginFlow",
  "actionType": "flow",
  "steps": [
    { "actionType": "basic", "actionId": "setProperty", "params": { "target": "#isLoading", "value": true }},
    { "actionType": "callback", "actionId": "restApi", "params": { "baseUrl": "#_appData.api.base", "path": "/login", "method": "POST", "body": { "u": "#userName", "p": "#password" }, "saveTo": "#_appData.session.auth" }},
    { "actionType": "basic", "actionId": "setProperty", "params": { "target": "#isLoading", "value": false }}
  ]
}
```

## 5. Metrics & Profiling

- Metrics server: hardened auth/CORS/rate limit; use `Authorization` header when required.
- Profile ingestion: POST to `/api/metrics/profile/ingest` (JSON timings from execution logs).
- Health checks: `/api/metrics/healthz` for readiness (used by CI).

## 6. Security Hardening

- Edge: JWT/HMAC toggles, CORS origins, rate limit, idempotency.
- Agent: REST host whitelist, expression sandbox, path validation, artifact sanitization.
- Do not expose secrets in code, logs, or docs.

## 7. Troubleshooting

- 401 Unauthorized → Provide `Authorization` token.
- 429 Too Many Requests → Observe `RateLimit-*`/`Retry-After`, reduce burst or raise limit briefly.
- ECONNREFUSED → Ensure metrics host up and `HOST` env set (e.g., `http://localhost:3100`).
- Ingest pending → Check bus events and `/figma-compat/uui/ingest/result`.

## 8. References

- Scenarios: `docs/manuals/COGO_User_Scenarios.md`
- Designer chatting guide: `docs/manuals/Designer_Chatting_Guide.md`

## 9. Protocols & Transports (Explicit)

- Edge Functions: All endpoints under `/figma-compat/*` are Edge Functions (short-lived). Label them as “Edge Function” in docs and code comments.
- Agent Services: Long-running compile/run/orchestrate are performed by the Agent (not Edge).

### 9.1 HTTP JSON (Edge/Agent APIs)
- Content-Type: `application/json`
- Auth headers (when enabled):
  - `Authorization: Bearer <ANON or JWT>`
  - `apikey: <PUBLISHABLE>` (Supabase)
  - Optional HMAC (if required): `x-signature: <HMAC>`
- Chat-facing shape includes `artifacts`:
```json
{
  "ok": true,
  "trace_id": "<uuid>",
  "response": "...",
  "artifacts": { "cogo_ui_json_preview": { /* small */ }, "links": [{"name":"cogo_ui_json","url":"https://...","mime":"application/json"}] }
}
```

### 9.2 Server-Sent Events (SSE)
- Transport: `text/event-stream`
- Events: `meta`, domain events (e.g., `rag.item`, `rag.done`, `llm.done`, `ui.generate`), final `done` with `artifacts`.

### 9.3 Realtime (Supabase)
- Channels: `trace:<trace_id>`

## 10. RAG Toggle & Samples

- Env: `ENABLE_RAG=true|false` (default: true)
- JSON sample (RAG off expected):
```bash
curl -sS -X POST "$BASE/design-generate" \
  -H 'content-type: application/json' -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  --data '{"prompt":"login without rag"}' | jq '{trace_id, rag_count: (.rag.count // 0), artifacts}'
```

## 11. Artifacts TTL/Bucket

- Env: `ARTIFACTS_BUCKET=artifacts` (default), `ARTIFACTS_SIGN_TTL_SEC=600` (default)
- `/_shared/artifacts.ts` respects these values for signing
