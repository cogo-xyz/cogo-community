## Realtime-First Exposure Policy (Dev vs Production)

### 1) Scope
- This document defines exposure rules for HTTP endpoints vs Supabase Realtime during development and production.
- Applies to all agents and services in `cogo-agent-core` (orchestrator, executor-dispatcher, codegen/build-test workers).

### 2) Principles
- Realtime-first: Inter-agent communication MUST use `public.agent_messages` and Realtime subscriptions.
- Edge-only ingress in production: External traffic should come via Edge Functions and queue to the bus.
- Development convenience: Minimal HTTP endpoints may be exposed to speed up local debugging.

### 3) Modes
- Development
  - Allowed to expose local endpoints for: orchestrator planning/execute, workflow/pipeline helpers, metrics, and integration status.
  - Docker compose may bind `3001:3000` for the API.
  - Workers still communicate via bus; no direct HTTP coupling between agents.
- Production/Staging
  - External ingress via Supabase Edge only.
  - Only strictly necessary HTTP endpoints (e.g., metrics) are exposed; all other flows run via Realtime.
  - Image-based deployment required; no bind-mounts.

### 4) Required Tests (must pass even in Development)
- Verify Realtime dispatch end-to-end:
  - Orchestrator → `execute` → Dispatcher → target worker via bus.
  - Codegen → Build/Test workflow emits and consumes Realtime events.
- Traceability:
  - All events and messages carry `trace_id`; `/api/metrics/trace/{traceId}` correlates `bus_events` and `agent_messages`.
- Acceptance gates:
  - Failure rate, p90 latency, decision quality thresholds enforced via CI script.

Recommended commands:
```
# Dispatcher E2E (bus enqueue + worker completion)
npm run -s smoke:dispatcher:e2e

# Workflows E2E (indexing, codeBuildTest)
npm run -s smoke:workflows:e2e

# Gate enforcement over a trace
npm run -s smoke:gate:trace

# Aggregate acceptance gates
npm run -s ci:gates:accept
```

### 5) HTTP Endpoints Allowed in Development
- Orchestrator: `/api/orchestrator/*` (plan/state/execute)
- Workflows: `/api/workflows/*` (templates/execute/gate)
- Pipeline: `/api/pipeline/*` (codeBuildTest/indexing/execute)
- Integration: `/api/integration/status`
- Metrics: `/api/metrics/*` (latency, events, trace, decision-quality)

Notes:
- These endpoints are aids for local debugging, not substitutes for Realtime flows.
- Production exposure must be minimized; migrate ingress to Edge Functions.

### 6) Configuration (Dev)
- `PORT=3000` (API internal), mapped to `3001:3000` via compose.
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (centrally managed—do not commit keys).
- `ENABLE_COGO_WORKER`, `COGO_WORKER_URL`, `COGO_WORKER_TIMEOUT_MS` for Python `cogo-worker` integration.
- `ARTIFACTS_BASE` for local artifact store (served under `/artifacts`).

### 7) Deployment Guidance
- Development: compose with bind mount acceptable; convenience endpoints allowed.
- Staging/Production: image-based rollout with releases/symlink or registry pull; remove bind mounts; only necessary ports exposed; Realtime subscription drives agent workflows.

### 8) Security & Secrets
- Never commit/paste secrets. Use centralized key management.
- Edge ingress: `Authorization: Bearer <ANON JWT>`, `apikey: <PUBLISHABLE>`.
- DB writes: service/secret role only.

### 9) Checklist (PR/Release)
- [ ] E2E Realtime tests pass (`smoke:dispatcher:e2e`, `smoke:workflows:e2e`).
- [ ] Gate criteria satisfied (`ci:gates:accept`).
- [ ] `trace_id` visible end-to-end via `/api/metrics/trace/{traceId}`.
- [ ] Dev-only endpoints documented in changelog; production exposure minimized.
