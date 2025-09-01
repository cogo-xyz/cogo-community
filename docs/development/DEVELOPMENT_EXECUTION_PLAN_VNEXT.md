## Development Execution Plan – Beta Ops & Quality

### 1) Metrics & Dashboard
- Add `/api/metrics/quality/gate/recent` for recent gate_fix with artifacts
- Extend `/dashboard/local` with:
  - Metrics summary (retries/DLQ, tokens/cost)
  - Build/Test latency (avg, p90)
  - Recent gate_fix artifacts with links
  - Provider Health (last 60m)

### 2) Quality Gate – Q1
- Scripts
  - `ci:gate:q1` (metrics summary based)
  - `ci:gate:q1:sb` (Supabase direct query, recommended)
- CI
  - `.github/workflows/quality-gate.yml` for PR gating (threshold default 70%)

### 3) Weekly Ops & Notification
- Enqueue weekly: `POST /api/schedule/weekly`
- Runners (short live): `npm run -s live:plan && npm run -s live:work`
- Notification
  - Local metrics based: `notify:weekly`
  - Supabase-based: `notify:weekly:sb` (includes recent gate_fix artifact links)

### 4) Router v2 Validation
- `router:compare:v1v2` using absolute `ROUTER_SELECT_URL`
- Headers: Authorization=ANON, apikey=PUBLISHABLE

### 5) Scheduled Operations
- `.github/workflows/scheduled-ops.yml`
  - Nightly snapshot, weekly enqueue, manual dispatch

### 6) Environment
- SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_PUBLISHABLE_KEY
- ROUTER_SELECT_URL, KEY_VAULT_URL

## COGO Agent Core – Execution Plan vNext (Distributed, End-to-End)

Status: Private repo, Free plan. Governance is policy-based per `docs/MINIMAL_WORKFLOW.md`. Technical guardrails (Rulesets/Branch protections) are non-enforced until upgrade.

This plan converges reliability, communication, state, security, observability, knowledge (RAG/KG), and GitHub/CI/CD into a single execution track. It balances risk/speed/quality and grows capabilities in small, verifiable steps.

---

### Phase 1 – Distributed Core Reliability (Highest Priority)

Acceptance Criteria
- Job state machine is formalized and consistently applied: `queued → assigned → running → succeeded | failed | cancelled`.
- Global idempotency keys (jobs/events/workflows); no duplicate claims under concurrency tests.
- Saga/compensation patterns for multi-step flows; DLQ with staged failure reasons.
- Metrics and tracing in place: throughput, p50/p95 latency, failure rate, retries, DLQ, lease renewal rate, zero claim-conflict.

Minimal Actions (Now)
- Spec: Job State Machine v1 (states, transitions, invariants).
- Spec: Idempotency/Saga/Compensation v1 (keys, retry/backoff, DLQ stages).
- Spec: Message Schema v1 (id, correlation_id, cause, version, payload).
- Implement HTTP/Job metrics and expose Prometheus endpoint `/metrics` (added). Expand instrumentation across claim/lease/RPC/search.
- Add a minimal regression script to CI (visibility-only on Free plan).

Artifacts
- `docs/specs/STATE_MACHINE_V1.md`
- `docs/specs/SAGA_AND_COMPENSATION_V1.md`
- `docs/specs/MESSAGE_SCHEMA_V1.md`

---

### Phase 2 – Complete Core Functions per Agent

Acceptance Criteria
- Indexing: incremental indexing for code/docs/knowledge; replay; sparse+embedding (BGE‑M3, 1024D) with governance.
- Research: evidence-backed summarization and internal-first retrieval.
- CodeGen: diff generation (dry‑run) → tests → report; security/quality checks.
- Executor: standard queue semantics (lease/retry/compensation) honored.

Minimal Actions
- Tokenization upgrade for code FTS (camelCase split, content expansion); keep sparse as first-class.
- Script incremental indexing + replay flows.
- Unify test runner I/O (agent test inputs/outputs standardized).

---

### Phase 3 – Orchestrator Autonomy Loop

Acceptance Criteria
- RAG → Plan → Route → Validate (tests) → Knowledge update loop success rate ≥ 0.7.
- 0-hallucination via mandatory citations; hit@3 ≥ 0.75.
- Failures take compensation/retry paths as designed.

Minimal Actions
- Connect hybrid search paths (docs/knowledge/code) with fixed parameters (th=0.05; blend 0.5/0.5; code th 0.0–0.05).
- Automate dry‑run (diff/tests) and produce PR drafts with evidence + checklist.
- CI gates (regression/security/bench) visible; auto‑merge considered post-upgrade.

---

### Phase 4 – Autonomy Scale + Governance

Acceptance Criteria
- Orchestrator‑centric domain templates (e‑commerce/SNS) for scaffolding/refactoring.
- Self‑tuning from knowledge/code/runtime KPIs (params/indexing/search strategies).
- Human role focuses on Fixer (exceptions/security/policy).

Minimal Actions
- GitHub governance standardization (owners, minimal workflow, secrets/OIDC, baseline CI).
- PR automation (labels/approvals) by risk profile.
- Operations runbook + SLA and alerting.

---

### Cross‑Cutting To‑Do Map (Horizontal)

Orchestration/Scheduling
- Sharding/routing by executor/type_prefix/tenant; worker pool routing policy.
- Scheduling policies: FIFO/priority/delayed (next_run_at)/work‑stealing.
- Leadership/coordination: leader election if needed; single scheduler; lease renewal KPIs.

State Model/Consistency
- Formal job state machine; transition rules.
- Global idempotency (jobs/events/workflows) and saga/compensation patterns.
- Retry/backoff and staged DLQ (collect failure reasons by stage).

Communication/Message Spec
- Event schema standardization (version, correlation_id, causality).
- Pub/Sub channel naming and permissions (tenant/agent/type_prefix basis).
- Inter‑agent request/response JSON Schema for interoperability.

Reliability/Scalability
- Autoscale triggers: queue depth/latency/failure rate.
- Prefetch/backpressure: per‑worker `prefetch_max`, throughput limits.
- Chaos/failure injection: RPC failures, network latency, worker crash scenarios.

Security/Tenancy
- Agent auth/JWT issuance & rotation; scope (read/write/RPC).
- Revisit RLS: minimize `service_role`, enforce tenant isolation.
- Secrets/env keys per environment/tenant; rotation procedure.

Observability/Operations
- Metrics: throughput, p50/p95, failure rate, retries/DLQ, claim conflicts=0, lease renewal rate.
- Tracing: propagate `trace_id`/`correlation_id` (job → event → RPC).
- Dashboards/alerts: SLA/SLO thresholds (latency/failure).

Knowledge Pipeline (RAG/KG)
- Distributed indexing with clear worker roles; incremental & replay flows.
- Embedding/sparse governance (dimension/model/tokenization) centralized.
- KG consistency: node/edge versioning, lineage, backpressure handling.

Centralized LLM Routing & Key Management (Supabase + Edge Functions)
- Single source of truth for keys in `secure_keys` (+ audit in `secure_keys_audit`).
- Routing metadata: `llm_providers`, `llm_models`, `routing_policies`, `provider_health`, `usage_counters`.
- Edge Functions:
  - `key-vault`: field-based lookup/upsert; dev plaintext, prod ciphertext; audit & usage touch.
  - `router-select` (new): choose {provider, model, region, base_url, headers} based on policy/health/cost/context.
- Orchestrator integration: call `router-select` → fetch key via `key-vault` → invoke LLM; fallback to direct path on outage.
- Security: no long-lived keys on agents; RLS; rotation; quotas; rate-limit at function or proxy.
- Reference: Claude Code Router patterns for routing/transformers (inspiration only).

DeepAgents-Aligned Reasoning Loop (Thinking as Data)
- Standardize LLM I/O as JSON; store actor thinking as evaluable objects, not free text.
- Actor–Critic–Gate: actor emits plan_step, tools run, critics verify, gate decides.
- Supabase schema: `plans`, `plan_steps`, `tool_runs`, `critic_verdicts`, `branch_tree`, `agent_subagents`, `agent_tools`, `file_snapshots`.
- Neo4j concept graph: Plan/Step/Thought/Critique/Tool/Run/Artifact/Knowledge relations.
- Docs: `docs/specs/THINKING_AS_DATA_AND_ACTOR_CRITIC_V1.md`, SQL: `docs/supabase/sql/DEEP_AGENTS_SCHEMA.sql`.

API Gateway/Ingress
- External request boundary to orchestrator (rate‑limit/auth/admission control).
- Long‑running requests to async (polling/callback/webhook).

GitHub/CI/CD
- Branch protection (reference only on Free), baseline CI, secrets standardization.
- PR generation/summarization/citation/checklist automation (cogo0 outputs).
- CI: hybrid 3‑path, queue regression, benches.
- CD: staging→production; feature flags.

---

### Gaps vs Current (Prioritized)

P0 (Immediate)
- Global idempotency/saga/compensation not specified; missing standard DLQ flow.
- Communication schema (correlation/causality/version) incomplete.
- Observability: SLA metrics, tracing, dashboards, alerts not in place.
- Security/RLS/tenancy least‑privilege model needs concrete definition.

P1 (Short Term)
- Distributed indexing role split; incremental sync; backpressure handling.
- Code FTS tokenization upgrade (sparse as primary, FTS as secondary).
- Autoscale/backpressure/prefetch parameter tuning.
- Centralized LLM Routing & Key Mgmt: `router-select` spec + minimal function; provider/model tables; orchestrator call path.
- Thinking as Data (Phase 2 prep): add Supabase tables (`DEEP_AGENTS_SCHEMA.sql`), add message JSON envelope in types, no runtime use yet.

P2 (Mid Term)
- PR automation (approvals/labels/release notes) maturity.
- KG versioning/lineage/schema evolution pipeline.
- LLM proxy with streaming/caching/quotas; A/B policies; per-tenant budgets.
- DeepAgents loop MVP: implement Actor–Critic–Gate on top of new tables; code agent critics (compile/lint/test) as required gates; dashboards.

---

### Immediate Execution (This Week)

Deliverables
1) Specs
   - `docs/specs/STATE_MACHINE_V1.md` – states, transitions, invariants, error classes.
   - `docs/specs/SAGA_AND_COMPENSATION_V1.md` – idempotency keys, retry/backoff (jitter), staged DLQ, compensation flows.
   - `docs/specs/MESSAGE_SCHEMA_V1.md` – JSON schema with `id`, `correlation_id`, `cause`, `version`, `payload`.

2) Instrumentation
   - HTTP latency metrics and `/metrics` endpoint [in place].
   - Insert counters/histograms around claim/lease/retry/DLQ and RPC/search paths.
   - Minimal Grafana dashboard sketches in `docs/grafana/` (optional mock).

3) CI Visibility
   - Minimal CI job running `npm ci && npm run -s lint --if-present && npm run -s build --if-present && npm run -s test --if-present` (already configured).
   - Add a lightweight regression script stub (no secrets) and publish as an artifact.

4) Security & RLS Baseline (Spec only)
   - Document least‑privilege policies, JWT scopes for agents, key rotation procedure.
   - RLS policy review checklist for `jobs`, `artifacts`, `worker_devices`, `worker_heartbeats`.

Ownership
- Reliability (Phase 1): Owner `cogo-0`. Backup `CreateGo-James`.
- Agent cores (Phase 2): Lead `fixers`.
- Orchestrator loop (Phase 3): Lead `cogo-0`.
- Governance (Phase 4): Owner `cogo-0` with `fixers` support.

Notes
- Private + Free plan: enforcement is policy‑based; we rely on `docs/MINIMAL_WORKFLOW.md` and CI visibility until upgrade.
- All comments/logs/docs must be in English; prompts generated in English.

---

### Acceptance Review – Weekly
- Evidence includes: specs, CI logs, metrics snapshots, regression reports, and PRs with citations.
- A phase is “Done” only when acceptance criteria above are met and verified by at least one reviewer from `fixers`.


