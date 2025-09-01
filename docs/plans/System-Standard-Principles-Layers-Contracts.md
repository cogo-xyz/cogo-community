# System Standard: Principles → Layers → Contracts → Workflows → Deployment → Observability → Security → Validation

This document consolidates the system-wide standards in the prescribed order and serves as the source of truth for implementation plans.

## 1) Principles
- Single realtime subscription per container; central bus `public.agent_messages` with routing keys `(service, role, shard, tenant)`
- Orchestrator = brain (Plan/Allocate); Executor = dispatcher (policy enforcement); Worker = single action
- All execution must honor `payload.__assignment` (budget/TTL/model/version)
- Edge only handles ingress (JWT/apikey validation); DB writes use function runtime key

## 2) Layers (Clear Responsibilities)
- Edge: `orchestrator-chat` → enqueue to bus
- Orchestrator: `decide` (plan), `execute` (publish standardized assignments)
- Executor: `cogo-executor-dispatcher` (budget/TTL/model/backoff/audit)
- Workers: `cogo-gateway-chat`, `cogo-rag-embed`, `cogo-kg-builder`, ...
- Ops: `cogo-bus-reclaimer`, `cogo-bus-retention`, `cogo-metrics-server`

## 3) Contracts
- Bus row: `service, role, shard, tenant, payload, status, attempts, retry_at, result_*`
- Assignment schema (inside payload): `__assignment: { agent_id, version, model, budget:{maxCostUsd,maxTokens}, ttl_ms }`
- Edge call: `POST { tenant, intent, payload }` → `202 { id }`

## 4) Workflows (Owned by Orchestrator)
- Engine: LangGraph (or equivalent interface) within Orchestrator
- Node types: Publish(bus), Wait(condition/event), Retry(backoff), Gate(assert), Notify
- Baselines:
  - Indexing: ReceiveDocEvent → Enqueue(rag/embed) → Wait → Enqueue(kg/build) → Wait → Done
  - Codegen→Build→Test: Generate → Build → Test → Gate → Report/Promote
  - Upgrade: proposal → evaluate → promote/rollback
- Orchestrator API: `POST /api/orchestrator/plan`, `POST /api/orchestrator/execute`, `GET /api/orchestrator/state`

## 5) Deployment (Standard Names)
- Processes: `cogo-orchestrator-brain`, `cogo-executor-dispatcher`, `cogo-gateway-chat`, `cogo-rag-embed`, `cogo-kg-builder`, `cogo-rag-dispatcher`, `cogo-bus-reclaimer`, `cogo-bus-retention`, `cogo-metrics-server`
- Edge: `orchestrator-chat`
- Sharding: default `shard=0`; scale out to N shards with key consistency

## 6) Observability / Quality
- Decision quality: correct routing rate, queue wait p50/p90, failure trend
- Cost/tokens/memory/time aggregated by assignment
- Dashboard cards: decision quality, bus wait, failures count, recent gate status

## 7) Security / Authorization
- Edge headers: `Authorization=Bearer <Anon>`, `apikey=<Publishable>`
- DB writes via function runtime `SERVICE_ROLE`
- Principle of least privilege; verify table-level permissions; apply RLS where needed

## 8) Validation (Acceptance)
- E2E: Edge→Orch→Exec→Worker→Result for Indexing/Codegen/Upgrade
- Bus failures < 5% (last 24h), avg wait < 5s, decision quality ≥ 85%

## 9) Immediate Execution Order (Dev)
1) Executor split: `cogo-executor-dispatcher` subscribes `orchestrator/execute/0`; standardize enforcement and audit
2) Codegen→Build→Test minimal line: `cogo-codegen-service`, `cogo-build-test-worker`; surface metrics and gates
3) Orchestrator workflows: start with Indexing and Code-Build-Test
4) Observability/Dashboard upgrade: decision quality, wait distribution, failure trend, alerts

References:
- `docs/AGENT_ARCHITECTURE_OVERVIEW.md`
- `docs/plans/Distributed-Agents-Naming-and-Deployment.md`
- `docs/plans/Implementation-Plan.md`

