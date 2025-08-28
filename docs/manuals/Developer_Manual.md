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

## 9. Protocols & Transports (Explicit)

- Edge Functions: All endpoints under `/figma-compat/*` are Edge Functions (short-lived). Label them as “Edge Function” in docs and code comments.
- Agent Services: Long-running compile/run/orchestrate are performed by the Agent (not Edge).

### 9.1 HTTP JSON (Edge/Agent APIs)
- Content-Type: `application/json`
- Auth headers (when enabled):
  - `Authorization: Bearer <JWT>`
  - `apikey: <PUBLISHABLE>` (Supabase)
  - Optional HMAC (if required): `x-signature: <HMAC>`
- Minimal request/response shape:
```json
{
  "trace_id": "<uuid>",
  "input": { /* domain-specific payload */ }
}
```
```json
{
  "ok": true,
  "trace_id": "<uuid>",
  "data": { /* result */ },
  "error": null
}
```

### 9.2 Server-Sent Events (SSE)
- Transport: `text/event-stream`
- Event fields: `event:` (optional), `data:` (JSON), `id:` (optional)
- Example frame:
```
event: message
data: {"trace_id":"...","type":"progress","payload":{"step":"compile","pct":42}}

```

### 9.3 Realtime (Supabase)
- Channels: `cogo:agent:<agent_id>` or flow-specific `trace:<trace_id>`
- Message JSON:
```json
{ "trace_id":"...", "type":"event|log|result", "payload":{ /* domain */ } }
```
- Use Realtime for async notifications; fall back to HTTP polling if disabled.

## 10. Figma Ingestion & Inputs

Two paths are supported.

### 10.1 Via Figma Plugin (Recommended)
- Configure Figma Access Token in the Plugin settings (never paste in chat/docs).
- Select component/page in Figma, then “Send to Agent”. The plugin calls Edge Functions (Edge) to presign and ingest.
- Data sent (typical): `{ file_url, page_url, node_id(s), selection_meta }` → returns `ingestId`.
- In Chatting, reference the ingest: “Use ingestId <id> from my last Figma selection and generate BDD for #onLoginClicked.”

### 10.2 Via Chat Only (No Plugin)
- Provide a public Figma URL (file or page). Private files require token; do not paste tokens into chat.
- If private: use a secure presign endpoint (Edge) operated by the team that holds the token centrally; pass only the URL in chat.
- Minimal chat prompt:
```
Generate symbols/variables for this Figma page: <FIGMA_PAGE_URL>.
Only use centrally configured tokens via Edge presign; do not request tokens from me.
```

## 11. Chatting Inputs for COGO UI JSON → Variables/Symbols/BDD/ActionFlow

When working from existing COGO UI JSON:
- Provide either a small JSON snippet or a reference (artifact id/URL). Prefer references for large payloads.
- Specify the page/scope and goal.

Example prompt:
```
Scope: loginPage
Goal: derive symbols/variables and draft BDD for #onLoginClicked.
Artifact: https://.../artifacts/ui/login.json (COGO UI JSON)
Output: mapping (#symbol → #_appData/#_uiState), BDD, ActionFlow skeleton (undecided → actionType:"none").
```

Minimum fields expected by the compiler when sending raw JSON via API:
```json
{
  "trace_id": "...",
  "input": {
    "ui_json": { /* COGO UI JSON */ },
    "page": "loginPage",
    "goals": ["symbols","variables","bdd","actionflow"]
  }
}
```
