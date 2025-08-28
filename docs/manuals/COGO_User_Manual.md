# COGO Agent – User Manual

This manual explains how to use the COGO Agent from ingestion (Figma/UUI/COGO JSON) through variables, BDD, actions, ActionFlow execution, and operations. It complements the User Scenarios document.

## 1. Architecture Overview

- Edge Functions (e.g., `figma-compat`): short-lived API for conversion, ingestion, and lightweight triggers under `/figma-compat/uui/*`.
- COGO Agent Services: compile BDD→ActionFlow, execute flows, manage variables/symbols, integrate RAG/pgvector & KG/Neo4j, record metrics/profiles.
- Metrics Server: authentication/CORS/rate-limit hardened; exposes health and profile ingest endpoints.

## 2. Prerequisites

- Project created and accessible
- Required environment variables managed centrally
- Network access to Agent services and Metrics server

## 3. Ingestion & Conversion (Edge)

Endpoints (POST unless specified):
- `/figma-compat/uui/symbols/map`
- `/figma-compat/uui/variables/derive`
- `/figma-compat/uui/bdd/generate`, `/figma-compat/uui/bdd/refine`
- `/figma-compat/uui/actionflow/refine`
- `/figma-compat/uui/generate`, `/figma-compat/uui/generate/llm`
- `/figma-compat/uui/presign`, `/figma-compat/uui/ingest`

Notes: CORS/idempotency/rate limits apply; keep requests short-lived.

## 4. Variables and Symbols

- Symbols: `#symbol` placeholders in UI JSON
- Variables: `appData.Page.*` (content), `uiState.Page.*` (state/style)
- Mapping: deterministic paths (e.g., `"#userName" → "#_appData.loginPage.userName"`)
- Initialization: initial/default from current UI JSON when present

## 5. BDD and ActionFlow

- BDD per event (Given/When/Then) referencing symbols
- Agent compiles to ActionFlow (`actionType`, `actionId`, `params`, `guards`)
- Undecided steps → `actionType: "none"` until confirmed

## 6. Data Actions (API)

- `api_call` with host whitelist (`REST_ALLOWED_HOSTS`)
- Optional idempotency at Edge; retries/backoff in Agent
- Response mapping with validated `saveTo` paths

## 7. Execution (Agent Runner)

- Run flows in Agent runtime (not Edge)
- Timeouts, retries, circuit breakers
- Optional detailed timings (binding/whitelist/fetch/parse/branches)

## 8. Metrics & Profiling

- Metrics endpoints (auth if enabled): health, summaries, profile ingest
- Artifacts: execution logs and profiles

## 9. Security & Gates

- Edge: JWT/HMAC, CORS origin, rate limit, idempotency
- Agent: REST whitelist, expression sandbox, sanitization
- CI gates: BDD/RAG/KG, error rate, step sanity

## 10. Troubleshooting

- 401: provide Authorization token
- 429: observe RateLimit headers or reduce burst
- ECONNREFUSED: ensure Metrics server ready and HOST set
- Ingest pending: check bus events and `/ingest/result`

## 11. References

- Designer Guide: `docs/methodology/172.CreateGo Designer Development Process Summary_Eng(20250326).docx.md`
- User Scenarios: `docs/manuals/COGO_User_Scenarios.md`
- Security & Metrics: `docs/runbook/SECURITY_METRICS.md`
