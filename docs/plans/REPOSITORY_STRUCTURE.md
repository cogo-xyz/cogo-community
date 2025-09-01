## COGO Repository Structure – Agentic, Secure, and Operationally Sound

This document consolidates the agreed repository layout and operating rules to enable an agentic (RAG + LLM) upgrade loop while preserving security and operational safety.

### 1) Core Repositories (Single Source of Truth)
- cogo-agent-core
  - Orchestrator/Workers/Edge functions/Bus integration (Supabase Realtime broadcast `trace:{traceId}`, `bus_events`)
  - Supabase ownership is centralized here: schemas, SQL, Edge functions, secrets management, and deployment are all developed and shipped from `cogo-agent-core`.
  - Agentic loop in one place (do NOT split):
    - perception/ingest: pgvector indexing, Neo4j sync, Edge `/rag/ingest`, `/rag/search`
    - planning: LLM planning/PRD/ADR, trace_id and evidence artifacts
    - execution: playbook-driven edits/migrations/tests/build, secret/denylist guards
    - evaluation: gates/evals (p50/p95, regression, security) with thresholds
    - governance: policy/approval matrix (human approval or auto when metrics OK)
    - rollout: release/canary/rollback orchestration, artifact retention
  - Observability: `/api/metrics/summary`, artifacts standardization, logs with `trace_id`

- cogo-platform-core
  - Application/platform-facing backend APIs, authorization/tenancy, production operations (no direct Supabase schema or Edge ownership here)
  - Receives automated PRs from `cogo-agent-core` (after gate success) and consumes the centralized Supabase assets produced by the agent

- cogo-packages
  - Core shared libraries (SoT), reusable, versioned (semver)
  - Consumers (platform/client) pin versions and upgrade explicitly

### 2) Client and Tooling Repositories (Consumers)
- cogo-client (Private)
  - apps/ide (web IDE), apps/starter-web (preview/runtime), apps/starter-flutter (optional)
  - packages/ui-kit, packages/state, packages/schemas, packages/client-helpers
  - Uses official SDKs, follows stream→Realtime handoff and artifacts standards

- SDK/Tools (Public)
  - cogo-chat-sdk-ts, cogo-chat-sdk-flutter
  - cogo-cli-flutter
  - cogo-figma-plugin
  - cogo-starter (if separated from cogo-client)

### 3) Public Monorepo (Artifacts/Docs Only)
- cogo-community (Public)
  - What to include: SDK/CLI/Plugin, guides, migration docs, minimal samples
  - What not to include: core runtime (orchestrator/workers/edge), secrets, internal ops scripts
  - Copy policy: allowlist only, exclude `node_modules`, `.dart_tool`, `dist/`, `build/`, `.env*`, `*key`, `*secret*`; timestamp backup before overwrite; never `rsync --delete` to $HOME

### 4) Standards and Policies
- Realtime and Events
  - Realtime broadcast channel: `trace:{traceId}` (performance-first)
  - Durable events: `bus_events` with `*_scheduled/succeeded/failed`

- Artifacts
  - Response contract: `{ bucket, key, signedUrl }`
  - `key` is bucket-relative; prefer using `signedUrl` for download

- Security (Production)
  - Edge flags: `REQUIRE_IDEMPOTENCY=true`, `EDGE_VERIFY_JWT=true`, `EDGE_REQUIRE_HMAC=true`
  - Secrets in Edge env/manager only (never in code/docs/logs)
  - Supabase keys and Edge runtime secrets are managed centrally by `cogo-agent-core`; consumers must not duplicate or fork these settings

- Deployment
  - Release directory + symlink switch (atomic); image-based rollouts preferred
  - No `rsync --delete` against broad/remote home directories

### 5) Migration Map (CreateGo → COGO)
- creatego-packages → cogo-packages (branch in original, refactor, tag; do not move SoT to community)
- creatego-backend → cogo-platform-core (backend core service; Supabase migrations/Edge are unified and moved to `cogo-agent-core`)
- creatego-starter → cogo-starter or apps/starter-* under cogo-client
- creatego-ide → apps/ide under cogo-client (last to migrate due to complexity)

Guidelines:
- Consumers adopt SDK standards: Authorization Bearer + `apikey`, SSE→`queued|handoff`→Realtime handoff, large payloads via `presign → PUT → ingest → result`.
- Realtime migration: prefer broadcast over Postgres Changes

### 6) Agentic Upgrade Loop (within cogo-agent-core)
- Loop: observe → plan → change → evaluate → release (single repo, fast cadence)
- Evidence: all steps record `trace_id`, artifacts (request/response/summary/error)
- Gates: eval thresholds must pass; else automatic rollback with reports
  - Supabase migrations and Edge deploys are gated and executed from here, ensuring the agent’s server-first improvement loop

### 7) Versioning, CI/CD, and Rollback
- Versioning: semver for packages; clients pin and upgrade explicitly
- CI gates: MCP health, E2E (optional), unified gate; publish artifacts
- Rollback: feature flags, canary, previous tag switch; keep logs and artifacts for replay

### 8) cogo-client Privacy and Public Distribution
- cogo-client stays Private by default
- Public distribution via `cogo-community` by copying only public-safe artifacts (docs/samples)
- Update community README with links and quickstarts; run a smoke test before publishing

### 9) Immediate Next Steps
- Adopt this layout in org (cogo-xyz) and create protected branches
- In `cogo-agent-core`, organize modules by loop stage (perception/planning/execution/evaluation/governance/rollout)
- In `cogo-client`, consolidate IDE and Starter; extract shared UI/state/schemas
- Publish/refresh community docs with SDK/CLI guides and Figma guides (already added)
- Consolidate all Supabase assets (SQL, Edge, config) under `cogo-agent-core` and remove duplicates from other repos

This structure preserves the agent’s autonomy (single-repo loop), keeps core SoT private, and enables safe public distribution of tools and guides.


