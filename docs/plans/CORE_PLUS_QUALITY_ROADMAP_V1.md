## Core + Quality-First Roadmap (Distributed Intelligent Agent)

Objective: Finish core Actor–Critic–Gate + RAG loop and prove end-user quality via scenario-based evaluation before any production setup.

### Phases
1) P0-CORE (done): JSON events, EventBus, LLM/Index wiring, minimal critics/gate, metrics, E2E green
2) P0-QUALITY (done/ongoing maintenance): Scenario suite + runner + automatic critics, nightly runs
3) P1-ROUTING/RELIABILITY (now): health-based routing + cost-aware + rate-limit backoff, provider_health pipeline
4) P1-INDEXING-SEARCH: AST tagging + hybrid search precision, tag-aware code lookup APIs
5) P1-QUALITY-EXPAND: 12–15 scenarios, weighted Gate policy, gate/cost/health audit APIs
6) P2-PLATFORM: cogo-platform ingestion and end-user scenarios across platform
7) P2-PRELAUNCH: encryption/KMS, quotas/limits, proxy, alerts, governance

### Quality-first Plan (P0-QUALITY)
- Scenario catalog (declarative JSON) under `scenarios/`
- Runner: execute scenarios → collect outputs/artifacts/evidence → JSON reports saved to `reports/quality/`
- Automatic critics:
  - Code: compile/typecheck/lint/test (progressive; start with contract check)
  - Docs/Search: citation required; groundedness@k (progressive)
- Gates: Q1 (task_success ≥ 0.7, groundedness@3 ≥ 0.75) to proceed to P1

### Immediate Deliverables (updated)
- APIs (monitoring)
  - GET /api/metrics/health (provider_health snapshot)
  - GET /api/metrics/routing (last N selections with policy/cost)
  - GET /api/metrics/gate (last N gate decisions with weights)
- Routing
  - Cost-aware scoring (metadata.cost_per_1k)
  - Backoff + re-route on 4xx/5xx with EWMA updates (done)
- Indexing
  - AST tags in `vector_documents`/`code_vectors` (done)
- Quality
  - Critics: Compile(+ESLint), Groundedness, Citation (done)
  - Nightly/health workflows (done)

### Files (delta)
- APIs: to be added under `src/routes/metricsRoutes.ts`
- Health reporter: `src/services/health/ProviderHealthReporter.ts` (done)
- Routing Edge: `supabase/functions/router-select/` (updated)


