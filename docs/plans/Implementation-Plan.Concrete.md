# Implementation Plan – Concrete Execution Details (Executor, Codegen→Build/Test, Orchestrator Workflows)

This document provides concrete file paths, APIs, message contracts, acceptance criteria, and rollout gates for the immediate implementation.

## 1) Executor Split – `cogo-executor-dispatcher`

- Bus subscription: `(service=orchestrator, role=execute, shard=0)`
- Input: `payload` includes `__assignment` (policy envelope)
- Guarantees: budget/token/time enforcement; uniform retry/backoff; audit events

### Files
- `src/workers/ExecutorDispatcher.ts`
- `src/orchestrator/Executor.ts` (builds assignment)
- `src/types/assignment.ts`
- `src/scripts/bus/reclaimer.ts` (existing)
- `src/scripts/bus/retention.ts` (existing)

### Pseudocode
```ts
// src/workers/ExecutorDispatcher.ts
// subscribe(agent_messages where service='orchestrator' and role='execute' and shard=0 and status='queued')
// claim→enforce(__assignment)→publish(target route)→insert bus_events
```

### Acceptance
- `bus_events` shows `execute_enqueued/execute_retry/execute_failed/execute_done`
- Violations are rejected with clear error and backoff populated

## 2) Codegen → Build/Test Pipeline

### Agents and Buses
- `cogo-codegen-service` on `(service=codegen, role=generate, shard=0)`
- `cogo-build-test-worker` on `(service=code, role=build-test, shard=0)`

### Artifacts
- `artifacts/<taskId>/edits.json`
- `artifacts/<taskId>/build-test/report.json`

### Endpoints
- `POST /api/workflows/execute { workflowId: "codeBuildTest", parameters: {...} }`
- `GET /api/metrics/workflows/codeBuildTest`

### Acceptance
- E2E PASS for a sample change; dashboard shows artifacts and gate verdict

## 3) Orchestrator Workflows (Indexing, Code-Build-Test)

### Files
- `src/workflows/indexing.ts`
- `src/workflows/codeBuildTest.ts`

### Node Types
- Publish(bus), Wait(event/condition), Retry(backoff), Gate(assert), Notify(webhook)

### APIs
- `POST /api/orchestrator/plan`
- `POST /api/orchestrator/execute`
- `GET /api/orchestrator/state`

### Acceptance
- Workflow state introspection works; events correlate with `bus_events`

## 4) Observability & Policies

### Metrics
- New: `/api/metrics/workflows/*`, `/api/metrics/bus/latency`
- Cards: decision quality, queue wait p50/p90, failure trend

### Policies
- Workers must honor `__assignment` (budget/TTL/model). Violations → fail + audit

## 5) Rollout & Gates

1. Dev E2E → 2. CI smoke → 3. Canary 10% → 4. Promote 100%
- Gates: zero regression in failure rate; latency within SLO; decision quality >= baseline

## 6) Risks & Mitigations
- Realtime hiccups → keep poll fallback and reclaim job
- Over-enforcement → tune thresholds and add bypass for canary

