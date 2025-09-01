### CreateGo-Agent Replacement Analysis (API Gateway, ActionFlow)

Objective: Replace CreateGo-Agent API Gateway and ActionFlow WebSocket Agent with COGO equivalents while enforcing domain separation (cogo vs public) and CQRS.

#### Source References
- variable-doc.md — Variables/state representation in IDE
- bdd-doc.md — BDD scenarios and refinement
- action-flow-doc.md — ActionFlow graph and runtime semantics

#### Target Architecture
- Edge Functions (Supabase):
  - `/figma-compat/uui/*` — conversion, generate, ingest (already implemented)
  - `/chat` and `/chat-gateway` — chat and SSE
  - `/agent/*` — agent enrollment/session/HMAC (JWT optional in dev)
- cogo schema (authoritative, SRK only):
  - `project_updates` outbox (status pipeline)
  - `bus_events` for audit/observability
- public schema (IDE-owned):
  - Materialized UI/project tables written by IDE via RLS

#### API Gateway Replacement
- CreateGo pattern → COGO mapping
  - REST endpoints consolidate under Supabase Edge functions
  - Idempotency via `Idempotency-Key`, auth via Anon/JWT/HMAC
  - Emission of events to `bus_events` with `x-agent-id` propagation
- Contracts:
  - Variables/Symbols/BDD endpoints → `/figma-compat/uui/*` family
  - Chat flows → `/chat` (canonical), `/chat-gateway` (compat)

#### ActionFlow WebSocket Replacement
- Original: Agent-side WS driving ActionFlow
- Replacement:
  - SSE for streaming outputs/events where possible
  - Realtime channels for collaboration (optional)
  - Projection model:
    - Agent emits to `cogo.project_updates` (outbox)
    - IDE materializes/upserts to `public.*` according to variable/bdd/actionflow docs

#### CQRS Mapping
- Command: IDE posts intents (e.g., variable updates, action triggers)
- Outbox: Agent enqueues `cogo.project_updates`
- Projection: Platform worker (or IDE-controlled function) writes to `public.*`
- Read: IDE queries `public.*` views; analytics from `cogo.*`

#### Data Contracts (Compat Layer)
- Variables JSON: align with variable-doc keys; prefer `cogo_ui_json` root for UI
- BDD JSON: `current_bdd`, `refinement_queries` endpoints retained
- ActionFlow JSON: `flow_id`, `current_flow`, `refinement_queries` retained

#### Observability & Idempotency
- All requests carry `trace_id` (returned in response or generated server-side)
- SSE streams include `meta`, `llm.delta`, `llm.done` markers
- `bus_events` captures `*_requested/succeeded/failed`

#### Security
- Dev: Anon permitted, `EDGE_VERIFY_JWT=false`, `EDGE_REQUIRE_HMAC=false`
- Prod: short-lived JWT and HMAC required; CORS restricted

#### Cutover Plan (High-level)
1) Stabilize compat endpoints on Edge (`/figma-compat/uui/*`, `/chat-gateway`)
2) IDE switches write path to `public.*`, read remains `public.*`
3) Agent writes only to `cogo.*` outbox and bus events
4) Rollout feature flags per endpoint; monitor via `/artifacts` and metrics
