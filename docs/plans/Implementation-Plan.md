# Implementation Plan (Base → Concrete)

This plan follows the standard order “Principles → Layers → Contracts → Workflows → Deployment → Observability → Security → Validation” and derives from:
- `docs/AGENT_ARCHITECTURE_OVERVIEW.md`
- `docs/plans/Distributed-Agents-Naming-and-Deployment.md`

## Scope (Phase Next)
- Split execution as a dedicated agent (`cogo-executor-dispatcher`)
- Establish Codegen → Build/Test workflow
- Introduce Orchestrator-managed workflows for Indexing and Code-Build-Test
- Strengthen observability and policies (assignment enforcement)

## 1) Principles

- Single realtime subscription per container; central bus `public.agent_messages` with routing keys `(service, role, shard, tenant)`
- Orchestrator = brain (Plan/Allocate); Executor = dispatcher (policy enforcement); Workers = single-action executors
- All execution must honor `payload.__assignment` (budget/TTL/model/version)
- Edge only handles ingress (JWT/apikey validation); DB writes use function runtime key

## 2) Layers (Responsibilities)

- Edge: `orchestrator-chat` (ingress → bus enqueue)
- Orchestrator: `decide` (plan), `execute` (enqueue standardized assignment)
- Executor: `cogo-executor-dispatcher` (budget/TTL/model/backoff/audit)
- Workers: `cogo-gateway-chat`, `cogo-rag-embed`, `cogo-kg-builder`, ...
- Ops: `cogo-bus-reclaimer`, `cogo-bus-retention`, `cogo-metrics-server`

## 3) Contracts

- Bus row: `service, role, shard, tenant, payload, status, attempts, retry_at, result_*`
- Assignment (inside payload): `__assignment: { agent_id, version, model, budget:{maxCostUsd,maxTokens}, ttl_ms }`
- Edge ingress: `POST { tenant, intent, payload }` → `202 { id }`

## 4) Workflows (Orchestrator-owned)

- Engine: LangGraph (or equivalent)
- Node types: Publish(bus), Wait(condition/event), Retry(backoff), Gate(assert), Notify
- Baselines:
  - Indexing: ReceiveDocEvent → Enqueue(rag/embed) → Wait → Enqueue(kg/build) → Wait → Done
  - Codegen→Build→Test: Generate → Build → Test → Gate → Report/Promote
  - Upgrade: proposal → evaluate → promote/rollback
- APIs: `POST /api/orchestrator/plan`, `POST /api/orchestrator/execute`, `GET /api/orchestrator/state`

## 5) Deployment (Standard Names)

- Processes: `cogo-orchestrator-brain`, `cogo-executor-dispatcher`, `cogo-gateway-chat`, `cogo-rag-embed`, `cogo-kg-builder`, `cogo-rag-dispatcher`, `cogo-bus-reclaimer`, `cogo-bus-retention`, `cogo-metrics-server`
- Edge: `orchestrator-chat`
- Sharding: default `shard=0`; later expand to N shards

## 6) Observability & Quality

- Decision quality: correct routing rate, queue wait p50/p90, failure trend
- Cost/tokens/memory/time aggregated by assignment
- Dashboard: decision quality, bus wait, failures N, recent gate status

## 7) Security / Authorization

- Edge headers: `Authorization=Bearer <Anon>`, `apikey=<Publishable>`
- DB writes use function runtime `SERVICE_ROLE`
- Least privilege on tables; apply RLS if needed

## 8) Validation (Acceptance)

- E2E: Edge→Orch→Exec→Worker→Result; three flows (Indexing/Codegen/Upgrade) PASS
- Bus failure < 5% (24h), avg wait < 5s, decision quality ≥ 85%

## 9) Milestones

1) Executor Split (cogo-executor-dispatcher)
- Bus: `service=orchestrator, role=execute, shard=0`
- Input: ExecutionSpec from Orchestrator (`payload.__assignment` present)
- Responsibilities:
  - Enforce budget/ttl/model
  - Uniform retry/backoff (attempts/last_error_at/retry_at)
  - Audit: insert `bus_events` (execute_enqueued, execute_retry, execute_failed, execute_done)
- Acceptance:
  - Orchestrator emits execute messages after decide
  - Workers receive messages with `__assignment` and succeed under budget/ttl

Implementation files:
- `src/workers/ExecutorDispatcher.ts` (listener + policy enforcement)
- `src/orchestrator/Executor.ts` (assignment builder)
- `src/types/assignment.ts` (`AssignmentEnvelope` and policy types)

2) Codegen → Build/Test Pipeline
- Agents:
  - `cogo-codegen-service` (bus: `codegen/generate/0`)
  - `cogo-build-test-worker` (bus: `code/build-test/0`)
- Flow:
  - Orchestrator starts workflow → enqueue generate → wait → enqueue build-test → wait → report gate
- Outputs:
  - edits.json (delta), build/test metrics, gate verdict
- Acceptance:
  - E2E PASS with sample task, gate artifacts visible on dashboard

Artifacts/paths:
- `artifacts/<taskId>/edits.json`
- `artifacts/<taskId>/build-test/report.json`

3) Orchestrator Workflows (LangGraph or equivalent)
- Files:
  - `src/workflows/indexing.ts`
  - `src/workflows/codeBuildTest.ts`
- Node types: Publish(bus), Wait(event/condition), Retry(backoff), Gate(assert), Notify(webhook)
- Acceptance:
  - `POST /api/orchestrator/plan`/`execute` can start and inspect workflow state

APIs:
- `POST /api/orchestrator/plan`
- `POST /api/orchestrator/execute`
- `GET /api/orchestrator/state`

4) Observability & Policies
- Dashboard: decision quality card, queue wait p50/p90, failure trend, alerts
- Assignment enforcement: worker-level guards for budget/tokens/time; violations → fail + audit
- Acceptance:
  - Metrics endpoints report new cards; violations recorded in `bus_events`

Metrics additions:
- `/api/metrics/workflows/*`
- `/api/metrics/bus/latency`

## Changes Summary

- DB/SQL
  - Ensure `agent_messages` has `attempts/last_error_at/retry_at`, `result_snippet/result_url`
  - Optional partial index for queued rows
- API
  - `/api/orchestrator/state` includes weights/experiments snapshot later
  - Add `/api/orchestrator/plan`, `/api/orchestrator/execute`
- Processes (PM2/Docker)
  - Add: `cogo-executor-dispatcher`, `cogo-codegen-service`, `cogo-build-test-worker`

PM2 entries (ecosystem.config.js):
- `cogo-executor-dispatcher` → `src/workers/ExecutorDispatcher.ts` (service=orchestrator, role=execute, shard=0)
- `cogo-codegen-service` → `src/workers/CodegenBusWorker.ts` (service=codegen, role=generate, shard=0)
- `cogo-build-test-worker` → `src/workers/BuildTestBusWorker.ts` (service=code, role=build-test, shard=0)

## Rollout
- Dev → E2E (Edge to worker) → CI smoke → Canary (low traffic) → Promote

## Risks
- Budget/token enforcement overkill → tune thresholds
- Realtime hiccups → poll fallback kept
