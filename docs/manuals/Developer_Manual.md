# COGO Agent – Developer Manual

This guide targets developers integrating and operating the COGO Agent. It covers setup, APIs, pipelines, security, and concrete samples.

## 1. Setup & Environments

- Environment variables are centrally managed (no secrets committed).
- Services: Agent (compile/run/orchestrate), Metrics server, Edge (`figma-compat`) for ingestion/short tasks.
- Local readiness: ensure Metrics server availability before smokes/gates.

## 2. Pipelines & Artifacts

- BDD pipeline: parse → compile → run → RAG (pgvector) → KG (Neo4j) → reports/artifacts.
- Quality gates (examples): BDD coverage, RAG hit rate, KG edge counts, ActionFlow step sanity, error rate.
- Artifacts: execution logs, profiles, reports (served via `/artifacts`).

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
- Security & metrics: `docs/runbook/SECURITY_METRICS.md`
