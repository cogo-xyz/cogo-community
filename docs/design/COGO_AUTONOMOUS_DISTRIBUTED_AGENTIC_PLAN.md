# COGO Autonomous Knowledge+Intelligent Distributed Agentic Platform

## 1. Vision and Target Outcomes
- Build an autonomous, knowledge-rich, intelligent, distributed agentic platform that:
  - Accumulates domain knowledge (code blueprints + business knowledge) and uses it as first-class context.
  - Scales across user PCs, servers, and mobile via Supabase Realtime subscriptions and Edge Functions.
  - Synthesizes, renders, and upgrades applications defined by JSON-first contracts (UI, Data, Action & Action Flow).
  - Continuously self-improves through CBO-driven (Code Blueprint Object) drift detection and upgrade loops.

## 2. Core Architecture (Edge-first, Realtime, Distributed)
- Edge-first Services
  - Supabase Edge Functions: `chat`, `embed`, `rag`, `role-select`, `graph` with SSE, idempotency, error standard `{ok,error,code,via}`.
  - Observability: `trace_id` and `idempotency-key` propagation; optional bus_events publishing; metrics server aggregation.
- Distributed Agents
  - Orchestrator: LangGraph-based workflows; `edge_call`/`route`; evidence injection; timeout/backoff/retry.
  - Indexing Agent: code/docs chunking; embedding (BGE-M3) to pgvector; structural writes to Neo4j.
  - Research Agent: hybrid retrieval orchestration; external connectors; normalized evidence.
  - Executor Agent: sandboxed execution (browser/mobile/WS); artifacts; safety limits.
  - GraphRAG Agent: Neo4j HTTP v2 access; standardized errors and timeouts; RAG graph queries.
- Realtime & Queue
  - Channels: `agents:{id}`, `jobs:{id}`, `system:events`; Presence/Broadcast taxonomy.
  - Jobs: enqueue → lease/claim → execute → result; idempotency; DLQ.
- Knowledge Stores
  - Vector: pgvector documents with hybrid filters; quality metadata.
  - Graph: Neo4j constraints/indexes; blueprint structures/relations; versioned changes.
- JSON-first Application Composition
  - UI JSON, Data JSON, Action & Action Flow JSON as the canonical app contract.
  - Renderer + Action Runner to validate and execute composed apps headlessly.
- CBO (Code Blueprint Object)
  - Unified structure to capture components, interfaces, constraints, quality, workflow state, and knowledge context.

## 3. Design Components
- LangGraph Nodes
  - `edge_call` (chat/embed/rag/role-select/graph) with SSE and evidence capture.
  - `synthesize_json`: fuse evidence → UI/Data/Action/Flow JSON.
  - `validate_render`: headless render + static checks + action dry-runs.
  - `gate_rollout`: canary/flags, snapshot diffs, rollback hooks.
- Fusion Layer
  - Prompts + deterministic mappers that transform RAG evidence into JSON contracts.
  - Evidence policy: enforce citations, coverage, constraints.
- Renderer & Action Runner
  - Deterministic rendering in a sandbox; action execution safety (rate limits, permissions, mocks).
- Figma MCP Integration
  - Ingest design context → index to pgvector/Neo4j; produce initial blueprint hints for synthesis.

## 4. Functional Scope
- Ingestion & Indexing: code/docs/designs; incremental reindex; artifacts; recovery.
- Knowledge Graph: blueprint nodes/edges; constraints; lineage; versioning.
- Hybrid RAG: vector + graph + filters; router for strategies.
- Agentic Decision: role-select; plan/route; evidence-controlled generation.
- App Synthesis & Upgrade: JSON-first composition; dynamic updates; migration paths.
- Distributed Execution: resilient workers; lease/claim; DLQ; observability.

## 5. Evaluation Criteria and Methods
- Retrieval Quality
  - Metrics: hit@k, MRR, evidence precision/recall, groundedness (fact consistency), coverage.
  - Methods: curated queries, ablation tests (vector-only/graph-only/hybrid), domain (Shopify/Woo) packs.
- Synthesis & Render Quality
  - Metrics: render success rate, action execution success rate, validation error rate, schema conformance.
  - Methods: headless render tests; action dry-run suites; golden snapshots; mutation tests.
- Agentic Orchestration
  - Metrics: P50/P95 per node, success ratio, retry/backoff rates, DLQ count; cost/tokens per task.
  - Methods: LangGraph trace analysis; scenario playbooks; stress/load profiles.
- Distributed Reliability
  - Metrics: time-to-recover (TTR), duplicate-execution rate (idempotency), lease expiry recoveries.
  - Methods: fault injection; lease expiry simulations; network partitions.
- User Value & UX
  - Metrics: task completion rate/time, rollback ratio, revision depth, perceived quality (Likert), adoption.
  - Methods: scenario-based user tests; A/B on composition strategies; feedback capture.
- Security & Governance
  - Metrics: secret scan (0 critical), rate-limit events, RLS effectiveness, audit coverage.
  - Methods: gitleaks CI, synthetic abuse tests, audit log sampling.

## 6. Acceptance Gates (CI/CD)
- Edge Observability Bundle: SSE meta + idempotency + error format green.
- Orchestrator Smokes: `edge_call`+evidence; timeout/backoff.
- RAG Quality Gate: configurable thresholds for hit@k/MRR/groundedness.
- Synthesis Gate: render/action success thresholds; schema conformance; golden diff caps.
- Distributed Gate: enqueue→claim→execute E2E success ≥ 95%, P95 ≤ 5s.
- Security Gate: secret scan 0 critical; env completeness; rate-limit safeguards.

## 7. Roadmap (Milestones)
- M1 Stabilize Edge-first & Orchestrator (done/ongoing): standard errors, idempotency, observability; smokes green.
- M2 Distributed Agents Refactor: Indexing/Research/Executor/GraphRAG to Edge-first patterns; Realtime/Jobs hardening.
- M3 Synthesis MVP: fusion, renderer, runner, JSON v1, LangGraph nodes; quality gates.
- M4 Platform Integration: repository structure move-only; modular `src/platform/*`; docs/runbooks update.
- M5 CBO Auto-Upgrade Loop: drift detection, improvement proposals, gated rollout.
- M6 Quality/Observability Hardening: dashboards, SLOs, error budgets, cost controls.

## 8. Risks and Mitigations
- Domain doc quality variance → preprocessing, summarization, quality gates.
- Composition fragility → golden snapshots, render/action tests, staged rollout with flags.
- Distributed complexity → lease/claim tests, chaos/fault injection, DLQ workflows.

## 9. Implementation Links (Repo)
- Edge Functions & Clients: `supabase/functions/*`, `src/services/edge/*`
- Orchestrator & LangGraph: `src/workflow/LangGraphWorkflowEngine.ts`
- RAG Indexing & Stores: `src/scripts/ci/seedVectorDocuments.ts`, `src/knowledge/*`
- GraphRAG: `supabase/functions/graph`, `src/services/edge/EdgeGraphClient.ts`
- Figma MCP: `mcp-servers/figma-context/*`, `src/workers/FigmaRagIngestWorker.ts`
- CBO Model: `src/core/CodeBlueprintObject.ts`

## 10. Definitions (JSON Contracts Draft v1)
- UI JSON: components, layout, theming, variants, constraints.
- Data JSON: entities, fields, validations, data sources, access policies.
- Action JSON: actions, params, pre/post-conditions, effects, permissions.
- Action Flow JSON: graph of actions with guards, retries, timeouts, compensation.

## 11. Success Criteria (Go/No-Go)
- Synthesis: render + action success ≥ 95% on reference scenarios; groundedness ≥ target.
- Distributed: E2E success ≥ 95%, P95 ≤ 5s; recovery < 10s under injected faults.
- Security: 0 critical leaks; RLS enforced; rate-limit rules active.
- Adoption: pilot user tasks completed time ↓ ≥ 30%; rollback ratio ≤ 5%.
